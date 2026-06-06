// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Vault {

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // Function to receive ETH
    receive() external payable {}

    // Withdraw ETH from the contract
    function withdraw(uint256 amount) external {
        require(msg.sender == owner, "Not owner");
        require(address(this).balance >= amount, "Insufficient balance");

        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Transfer failed");
    }
}