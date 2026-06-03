// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract MultiSigWallet {

    address[] public owners;
    mapping(address => bool) public isOwner;

    uint256 public requiredApprovals;

    struct Transaction {
        address to;
        uint256 value;
        bool executed;
        uint256 approvalCount;
    }

    Transaction[] public transactions;

    // txId => owner => approved
    mapping(uint256 => mapping(address => bool)) public approved;

    event Deposit(address indexed sender, uint256 amount);
    event Submit(uint256 indexed txId, address indexed to, uint256 value);
    event Approve(address indexed owner, uint256 indexed txId);
    event Execute(uint256 indexed txId);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    modifier txExists(uint256 txId) {
        require(txId < transactions.length, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint256 txId) {
        require(!transactions[txId].executed, "Already executed");
        _;
    }

    modifier notApproved(uint256 txId) {
        require(!approved[txId][msg.sender], "Already approved");
        _;
    }

    constructor(
        address[] memory _owners,
        uint256 _requiredApprovals
    ) {
        require(_owners.length > 0, "Owners required");
        require(
            _requiredApprovals > 0 &&
            _requiredApprovals <= _owners.length,
            "Invalid approvals"
        );

        for (uint256 i = 0; i < _owners.length; i++) {

            address owner = _owners[i];

            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Duplicate owner");

            isOwner[owner] = true;
            owners.push(owner);
        }

        requiredApprovals = _requiredApprovals;
    }

    // Receive ETH
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // Submit transaction
    function submitTransaction(
        address to,
        uint256 value
    ) external onlyOwner {

        transactions.push(
            Transaction({
                to: to,
                value: value,
                executed: false,
                approvalCount: 0
            })
        );

        emit Submit(
            transactions.length - 1,
            to,
            value
        );
    }

    // Approve transaction
    function approveTransaction(
        uint256 txId
    )
        external
        onlyOwner
        txExists(txId)
        notExecuted(txId)
        notApproved(txId)
    {
        approved[txId][msg.sender] = true;

        transactions[txId].approvalCount += 1;

        emit Approve(msg.sender, txId);
    }

    // Execute transaction
    function executeTransaction(
        uint256 txId
    )
        external
        onlyOwner
        txExists(txId)
        notExecuted(txId)
    {
        Transaction storage txn = transactions[txId];

        require(
            txn.approvalCount >= requiredApprovals,
            "Not enough approvals"
        );

        txn.executed = true;

        (bool success, ) = payable(txn.to).call{
            value: txn.value
        }("");

        require(success, "Transaction failed");

        emit Execute(txId);
    }

    // Get total transactions
    function getTransactionCount()
        external
        view
        returns (uint256)
    {
        return transactions.length;
    }
}