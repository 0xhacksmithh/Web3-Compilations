// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// Reward Token
contract RewardToken is ERC20 {

    constructor() ERC20("RewardToken", "RWD") {
        _mint(msg.sender, 1_000_000 ether);
    }
}

/// Staking Contract
contract Staking is Ownable {

    IERC20 public stakingToken;
    IERC20 public rewardToken;

    // Reward rate per second
    uint256 public rewardRate = 1 ether;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public stakingTimestamp;
    mapping(address => uint256) public rewards;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);

    constructor(
        address _stakingToken,
        address _rewardToken
    ) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }

    // Stake tokens
    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        // Update rewards before changing stake
        _updateRewards(msg.sender);

        stakingToken.transferFrom(
            msg.sender,
            address(this),
            amount
        );

        stakedBalance[msg.sender] += amount;
        stakingTimestamp[msg.sender] = block.timestamp;

        emit Staked(msg.sender, amount);
    }

    // Withdraw staked tokens
    function withdraw(uint256 amount) external {
        require(
            stakedBalance[msg.sender] >= amount,
            "Insufficient staked balance"
        );

        _updateRewards(msg.sender);

        stakedBalance[msg.sender] -= amount;

        stakingToken.transfer(msg.sender, amount);

        stakingTimestamp[msg.sender] = block.timestamp;

        emit Withdrawn(msg.sender, amount);
    }

    // Claim rewards
    function claimRewards() external {

        _updateRewards(msg.sender);

        uint256 reward = rewards[msg.sender];

        require(reward > 0, "No rewards available");

        rewards[msg.sender] = 0;

        rewardToken.transfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    // View pending rewards
    function earned(address account)
        public
        view
        returns (uint256)
    {
        uint256 stakingDuration =
            block.timestamp - stakingTimestamp[account];

        uint256 pendingReward =
            (stakedBalance[account] *
                rewardRate *
                stakingDuration) / 1 ether;

        return rewards[account] + pendingReward;
    }

    // Internal reward updater
    function _updateRewards(address account) internal {
        rewards[account] = earned(account);
        stakingTimestamp[account] = block.timestamp;
    }
}