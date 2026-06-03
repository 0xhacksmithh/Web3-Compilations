// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract TrustlessEscrow {

    address public buyer;
    address public seller;
    address public arbiter;

    uint256 public amount;

    bool public buyerApproved;
    bool public sellerApproved;
    bool public fundsReleased;

    event Deposited(address indexed buyer, uint256 amount);
    event Approved(address indexed approver);
    event Released(address indexed seller, uint256 amount);
    event Refunded(address indexed buyer, uint256 amount);

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Not buyer");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Not seller");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Not arbiter");
        _;
    }

    constructor(
        address _seller,
        address _arbiter
    ) payable {

        require(msg.value > 0, "Deposit required");

        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;

        amount = msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    // Buyer approves fund release
    function approveByBuyer() external onlyBuyer {
        require(!fundsReleased, "Already finalized");

        buyerApproved = true;

        emit Approved(msg.sender);

        _releaseFunds();
    }

    // Seller confirms delivery/service
    function approveBySeller() external onlySeller {
        require(!fundsReleased, "Already finalized");

        sellerApproved = true;

        emit Approved(msg.sender);

        _releaseFunds();
    }

    // Internal release logic
    function _releaseFunds() internal {

        if (buyerApproved && sellerApproved) {

            fundsReleased = true;

            (bool success, ) = payable(seller).call{
                value: amount
            }("");

            require(success, "Transfer failed");

            emit Released(seller, amount);
        }
    }

    // Arbiter can refund buyer in disputes
    function refundBuyer()
        external
        onlyArbiter
    {
        require(!fundsReleased, "Already finalized");

        fundsReleased = true;

        (bool success, ) = payable(buyer).call{
            value: amount
        }("");

        require(success, "Refund failed");

        emit Refunded(buyer, amount);
    }

    // Check contract balance
    function getBalance()
        external
        view
        returns (uint256)
    {
        return address(this).balance;
    }
}