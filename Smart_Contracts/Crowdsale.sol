// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// ERC20 Token
contract SaleToken is ERC20 {

    constructor(uint256 initialSupply)
        ERC20("SaleToken", "STK")
    {
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }
}

// Crowdsale Contract
contract Crowdsale is Ownable {

    SaleToken public token;

    // Number of tokens per 1 ETH
    uint256 public rate = 1000;

    event TokensPurchased(
        address indexed buyer,
        uint256 ethSpent,
        uint256 tokensReceived
    );

    constructor(address tokenAddress) Ownable(msg.sender) {
        token = SaleToken(tokenAddress);
    }

    // Buy tokens with ETH
    function buyTokens() external payable {
        require(msg.value > 0, "Send ETH to buy tokens");

        uint256 tokenAmount = msg.value * rate;

        require(
            token.balanceOf(address(this)) >= tokenAmount,
            "Not enough tokens in contract"
        );

        token.transfer(msg.sender, tokenAmount);

        emit TokensPurchased(
            msg.sender,
            msg.value,
            tokenAmount
        );
    }

    // Withdraw collected ETH
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "ETH transfer failed");
    }
}