// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract AddressChecker {
    
    function isContract(address account) public view returns (bool) {
        return account.code.length > 0;
    }
}