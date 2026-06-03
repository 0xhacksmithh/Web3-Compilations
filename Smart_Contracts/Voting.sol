// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract Voting {

    mapping(address => bool) public hasVoted;
    mapping(uint256 => uint256) public votes;

    // Vote for a candidate
    function vote(uint256 candidateId) external {
        require(!hasVoted[msg.sender], "Already voted");

        hasVoted[msg.sender] = true;
        votes[candidateId] += 1;
    }

    // Get total votes for a candidate
    function getVotes(uint256 candidateId) external view returns (uint256) {
        return votes[candidateId];
    }
}