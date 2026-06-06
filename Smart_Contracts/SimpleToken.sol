// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract SimpleToken {

    mapping(address => uint256) public balances;

    constructor() {
        balances[msg.sender] = 1000 ether;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "Invalid address");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[to] += amount;

        return true;
    }
}