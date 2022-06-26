//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract EtherWallet{

    address payable public owner;

    struct receiveTransactions{
        address _from;
        uint amount;
        uint date;
    }

    struct sentTransaction{
        address _to;
        uint amount;
        uint date;
    }

    receiveTransactions[] public receivedTransactions;
    sentTransaction[] public sentTransactions;
    
    constructor(){
        owner = payable(msg.sender);
    }

    receive() external payable{
        receivedTransactions.push(receiveTransactions({
            _from: msg.sender,
            amount: msg.value,
            date: block.timestamp
        }));
    }

    function send(uint _amount, address payable _to) public {
        require(msg.sender == owner, "you aren't the owner");
        _to.transfer(_amount);
        sentTransactions.push(sentTransaction({
            _to: _to,
            amount: _amount,
            date: block.timestamp
        }));
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }
}
