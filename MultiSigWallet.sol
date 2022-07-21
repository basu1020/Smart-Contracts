// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract MultiSigWallet{
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);

    struct Transaction{
        address payable to;
        uint value;
        bytes data;
        bool executed;
        uint approvalCount;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public approved;

    modifier onlyOwner(){
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txId){
        require(_txId < transactions.length);
        _;
    }

    modifier notApproved(uint _txId){
        require(!approved[_txId][msg.sender],"You have already approved the transaction.");
        _;
    }

    modifier notExecuted(uint _txId){
        require(!transactions[_txId].executed, "Transaction is already executed");
        _;
    }

    modifier hasApproved(uint _txId) {
        require(approved[_txId][msg.sender],"you haven't approved the transactions");
        _;
    }

    constructor(address[] memory _owners, uint _required){
        require(_owners.length > 0, "owner's required atleast one");
        require(_required > 0 && _required <= _owners.length,
        "invalid required number of owners");

        for (uint i; i < _owners.length; i++){
            address owner = _owners[i];
            require(owner != address(0),"Invalid address, It is address zero");
            require(!isOwner[owner], "owner is not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }
 
    receive () payable external{
        emit Deposit(msg.sender, msg.value);
    }

    function submit(address payable _to, uint _value, bytes calldata _data)
    external
    onlyOwner 
    {
        transactions.push(Transaction({
            to:_to,
            value:_value,
            data:_data,
            executed: false,
            approvalCount: 0
        }));

        emit Submit(transactions.length - 1);
    }

    function revoke(uint _txId) 
    external 
    onlyOwner
    txExists(_txId)
    notExecuted(_txId)
    hasApproved(_txId)
    {
        approved[_txId][msg.sender] = false;
        transactions[_txId].approvalCount -= 1;
        emit Revoke(msg.sender, _txId);
    }

    function approve(uint _txId)
    external 
    onlyOwner
    txExists(_txId)
    notApproved(_txId)
    notExecuted(_txId)
    {
        approved[_txId][msg.sender] = true;
        transactions[_txId].approvalCount += 1;
        emit Approve(msg.sender, _txId);
    }

    function _getApprovalCount(uint _txId) private view returns (uint count){
        return transactions[_txId].approvalCount;
    }

    function execute(uint _txId) 
    external 
    txExists(_txId) 
    notExecuted(_txId)
    {
        require(_getApprovalCount(_txId) >= required, "approvals < required");
        Transaction storage transaction = transactions[_txId];

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");

        emit Execute(_txId);
    }
}