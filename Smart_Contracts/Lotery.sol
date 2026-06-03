// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract Lottery {

    address public manager;
    uint256 public ticketPrice = 0.01 ether;

    address[] public players;

    event TicketPurchased(address indexed player);
    event WinnerPicked(address indexed winner, uint256 prize);

    modifier onlyManager() {
        require(msg.sender == manager, "Not manager");
        _;
    }

    constructor() {
        manager = msg.sender;
    }

    // Buy a lottery ticket
    function buyTicket() external payable {
        require(
            msg.value == ticketPrice,
            "Incorrect ticket price"
        );

        players.push(msg.sender);

        emit TicketPurchased(msg.sender);
    }

    // Get contract balance (prize pool)
    function getPrizePool()
        external
        view
        returns (uint256)
    {
        return address(this).balance;
    }

    // Pick a winner
    function pickWinner() external onlyManager {

        require(players.length > 0, "No players");

        uint256 randomIndex =
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.prevrandao,
                        players.length
                    )
                )
            ) % players.length;

        address winner = players[randomIndex];

        uint256 prize = address(this).balance;

        (bool success, ) = payable(winner).call{
            value: prize
        }("");

        require(success, "Prize transfer failed");

        emit WinnerPicked(winner, prize);

        // Reset lottery
        delete players;
    }

    // Get all players
    function getPlayers()
        external
        view
        returns (address[] memory)
    {
        return players;
    }
}