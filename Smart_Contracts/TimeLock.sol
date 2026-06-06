// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract TimeLock {

    address public owner;
    uint256 public unlockTime;

    constructor(uint256 _unlockTime) payable {
        require(_unlockTime > block.timestamp, "Invalid unlock time");

        owner = msg.sender;
        unlockTime = _unlockTime;
    }

    // Allow contract to receive ETH
    receive() external payable {}

    // Withdraw funds only after unlock time
    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        require(block.timestamp >= unlockTime, "Funds are still locked");

        uint256 amount = address(this).balance;

        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Transfer failed");
    }
}