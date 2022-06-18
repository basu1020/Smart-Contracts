//SPDX-License-Identifier:GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Lottery{

    address payable[] public players;

    receive () payable external{
        require(msg.value == 0.1 ether);
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function pickWinner() public{
        require (players.length >= 3);

        uint r = random();
        address payable winner;

        uint index = r % players.length;

        winner = players[index]; 
        winner.transfer(getBalance());
        players = new address payable[](0);
    }
}

