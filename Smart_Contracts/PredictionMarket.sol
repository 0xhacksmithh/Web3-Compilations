// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract PredictionMarket {

    enum Outcome {
        Pending,
        Yes,
        No
    }

    struct Market {
        string question;
        uint256 endTime;
        bool resolved;
        Outcome winningOutcome;

        uint256 totalYesBets;
        uint256 totalNoBets;
    }

    address public owner;
    uint256 public marketCount;

    mapping(uint256 => Market) public markets;

    // marketId => user => amount
    mapping(uint256 => mapping(address => uint256)) public yesBets;
    mapping(uint256 => mapping(address => uint256)) public noBets;

    // prevent double claim
    mapping(uint256 => mapping(address => bool)) public claimed;

    event MarketCreated(
        uint256 indexed marketId,
        string question,
        uint256 endTime
    );

    event BetPlaced(
        uint256 indexed marketId,
        address indexed user,
        Outcome outcome,
        uint256 amount
    );

    event MarketResolved(
        uint256 indexed marketId,
        Outcome winningOutcome
    );

    event RewardClaimed(
        uint256 indexed marketId,
        address indexed user,
        uint256 reward
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier marketExists(uint256 marketId) {
        require(marketId < marketCount, "Invalid market");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// Create new prediction market
    function createMarket(
        string calldata question,
        uint256 durationInSeconds
    ) external onlyOwner {

        require(durationInSeconds > 0, "Invalid duration");

        uint256 marketId = marketCount;

        markets[marketId] = Market({
            question: question,
            endTime: block.timestamp + durationInSeconds,
            resolved: false,
            winningOutcome: Outcome.Pending,
            totalYesBets: 0,
            totalNoBets: 0
        });

        marketCount++;

        emit MarketCreated(
            marketId,
            question,
            block.timestamp + durationInSeconds
        );
    }

    /// Bet on YES outcome
    function betYes(uint256 marketId)
        external
        payable
        marketExists(marketId)
    {
        Market storage market = markets[marketId];

        require(block.timestamp < market.endTime, "Market ended");
        require(msg.value > 0, "Bet amount must be > 0");

        yesBets[marketId][msg.sender] += msg.value;
        market.totalYesBets += msg.value;

        emit BetPlaced(
            marketId,
            msg.sender,
            Outcome.Yes,
            msg.value
        );
    }

    /// Bet on NO outcome
    function betNo(uint256 marketId)
        external
        payable
        marketExists(marketId)
    {
        Market storage market = markets[marketId];

        require(block.timestamp < market.endTime, "Market ended");
        require(msg.value > 0, "Bet amount must be > 0");

        noBets[marketId][msg.sender] += msg.value;
        market.totalNoBets += msg.value;

        emit BetPlaced(
            marketId,
            msg.sender,
            Outcome.No,
            msg.value
        );
    }

    /// Resolve market outcome
    function resolveMarket(
        uint256 marketId,
        Outcome winningOutcome
    )
        external
        onlyOwner
        marketExists(marketId)
    {
        Market storage market = markets[marketId];

        require(block.timestamp >= market.endTime, "Market still active");
        require(!market.resolved, "Already resolved");
        require(
            winningOutcome == Outcome.Yes ||
            winningOutcome == Outcome.No,
            "Invalid outcome"
        );

        market.resolved = true;
        market.winningOutcome = winningOutcome;

        emit MarketResolved(marketId, winningOutcome);
    }

    /// Claim winnings
    function claimReward(uint256 marketId)
        external
        marketExists(marketId)
    {
        Market storage market = markets[marketId];

        require(market.resolved, "Market not resolved");
        require(!claimed[marketId][msg.sender], "Already claimed");

        uint256 userBet;
        uint256 winningPool;
        uint256 losingPool;

        if (market.winningOutcome == Outcome.Yes) {
            userBet = yesBets[marketId][msg.sender];
            winningPool = market.totalYesBets;
            losingPool = market.totalNoBets;
        } else {
            userBet = noBets[marketId][msg.sender];
            winningPool = market.totalNoBets;
            losingPool = market.totalYesBets;
        }

        require(userBet > 0, "No winning bet");

        claimed[marketId][msg.sender] = true;

        // proportional reward calculation
        uint256 reward =
            userBet +
            (userBet * losingPool) / winningPool;

        payable(msg.sender).transfer(reward);

        emit RewardClaimed(
            marketId,
            msg.sender,
            reward
        );
    }

    /// View total pool
    function getTotalPool(uint256 marketId)
        external
        view
        returns (uint256)
    {
        Market storage market = markets[marketId];

        return market.totalYesBets + market.totalNoBets;
    }
}