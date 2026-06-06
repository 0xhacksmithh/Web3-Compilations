// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract BalanceChecker {

    // Check ETH balance of any address
    function getBalance(address account) public view returns (uint256) {
        return account.balance;
    }
}