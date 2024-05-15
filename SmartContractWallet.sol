// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract smartContractWallet{
    address payable public owner;

    mapping(address => uint) public allowance;
    mapping(address => bool) public isAllowedToSend;

    mapping(address => bool) public guardians;

    address payable nextOwner;
    mapping(address => mapping(address => bool)) nextOwnerGuardianVotedBool;
    uint guardianResetCount;
    uint public constant confirmFromGuardianReset = 3;
    constructor(){
        owner = payable(msg.sender);
    }

    function setGuardian(address _guardian,bool _isGuardian) public {
        require(msg.sender == owner, "you are not the owner,aborting");
        guardians[_guardian] = _isGuardian;
    }

    function proposeNewOwner(address payable _newOwner) public {
        require(msg.sender == owner,"you are not guardian of the wallet,aborting");
        require(nextOwnerGuardianVotedBool[_newOwner][msg.sender]==false,"You already voted, aborting");
        if(_newOwner != nextOwner)
        {
            nextOwner = _newOwner;
            guardianResetCount =0;
        }

        guardianResetCount++;

        if(guardianResetCount >= confirmFromGuardianReset)
        {
            owner = nextOwner;
            nextOwner = payable(address(0));
        }
    }


    function setAllowance(address _for,uint _amount) public {
        require(msg.sender == owner, "you are not the owner,aborting");
        allowance[_for] = _amount;

        if(_amount > 0)
        {
            isAllowedToSend[_for] = true;
        }
        else{
            isAllowedToSend[_for] = false;
        }
    }

    function transfer(address payable _to, uint _amount, bytes memory _payload) public returns(bytes memory)
    {
        if(msg.sender != owner)
        {
            require(isAllowedToSend[msg.sender], "You are not allowed to send anything from this smart contract, aborting");
            require(allowance[msg.sender] >= _amount, "You are trying to send more than you are allowed to, aborting" );

            allowance[msg.sender] -= _amount;
        }
        (bool success,bytes memory returnData) = _to.call{value: _amount}(_payload);
        require(success,"Aborting,call not successful");
        return returnData;
    }

    receive() external  payable {}

}

contract Consumer {
    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function deposit() public payable {}
}