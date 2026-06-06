// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract BlindAuction {

    address public owner;

    uint256 public biddingEnd;
    uint256 public revealEnd;

    address public highestBidder;
    uint256 public highestBid;

    struct Bid {
        bytes32 blindedBid;
        uint256 deposit;
        bool revealed;
    }

    mapping(address => Bid[]) public bids;
    mapping(address => uint256) public pendingReturns;

    bool public ended;

    event BidSubmitted(address indexed bidder);
    event BidRevealed(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 highestBid);

    modifier onlyBefore(uint256 time) {
        require(block.timestamp < time, "Too late");
        _;
    }

    modifier onlyAfter(uint256 time) {
        require(block.timestamp > time, "Too early");
        _;
    }

    constructor(
        uint256 biddingTime,
        uint256 revealTime
    ) {
        owner = msg.sender;

        biddingEnd = block.timestamp + biddingTime;
        revealEnd = biddingEnd + revealTime;
    }

    // Submit blinded bid
    function bid(
        bytes32 blindedBid
    )
        external
        payable
        onlyBefore(biddingEnd)
    {
        bids[msg.sender].push(
            Bid({
                blindedBid: blindedBid,
                deposit: msg.value,
                revealed: false
            })
        );

        emit BidSubmitted(msg.sender);
    }

    // Reveal bid
    function reveal(
        uint256[] calldata values,
        bytes32[] calldata secrets
    )
        external
        onlyAfter(biddingEnd)
        onlyBefore(revealEnd)
    {
        Bid[] storage userBids = bids[msg.sender];

        require(
            values.length == userBids.length,
            "Invalid values length"
        );

        require(
            secrets.length == userBids.length,
            "Invalid secrets length"
        );

        uint256 refund;

        for (uint256 i = 0; i < userBids.length; i++) {

            Bid storage storedBid = userBids[i];

            require(!storedBid.revealed, "Already revealed");

            bytes32 computedHash =
                keccak256(
                    abi.encodePacked(
                        values[i],
                        secrets[i]
                    )
                );

            if (computedHash == storedBid.blindedBid) {

                refund += storedBid.deposit;

                if (
                    storedBid.deposit >= values[i] &&
                    values[i] > highestBid
                ) {

                    if (highestBidder != address(0)) {
                        pendingReturns[highestBidder] += highestBid;
                    }

                    highestBidder = msg.sender;
                    highestBid = values[i];

                    refund -= values[i];
                }
            }

            storedBid.revealed = true;

            emit BidRevealed(msg.sender, values[i]);
        }

        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }

    // Withdraw overbid funds
    function withdraw() external {

        uint256 amount = pendingReturns[msg.sender];

        require(amount > 0, "No funds");

        pendingReturns[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
    }

    // End auction
    function endAuction()
        external
        onlyAfter(revealEnd)
    {
        require(!ended, "Auction already ended");

        ended = true;

        emit AuctionEnded(
            highestBidder,
            highestBid
        );

        payable(owner).transfer(highestBid);
    }

    // Generate blind bid hash
    function generateBlindBid(
        uint256 value,
        bytes32 secret
    )
        external
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(value, secret)
        );
    }
}