// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleDEX is Ownable {

    IERC20 public tokenA;
    IERC20 public tokenB;

    // Exchange rate:
    // 1 tokenA = rate tokenB
    uint256 public rate;

    event Swapped(
        address indexed user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    constructor(
        address _tokenA,
        address _tokenB,
        uint256 _rate
    ) Ownable(msg.sender) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        rate = _rate;
    }

    // Swap TokenA -> TokenB
    function swapAForB(uint256 amountA) external {

        require(amountA > 0, "Invalid amount");

        uint256 amountB = amountA * rate;

        require(
            tokenB.balanceOf(address(this)) >= amountB,
            "Insufficient liquidity"
        );

        // User must approve tokenA first
        tokenA.transferFrom(
            msg.sender,
            address(this),
            amountA
        );

        tokenB.transfer(msg.sender, amountB);

        emit Swapped(
            msg.sender,
            address(tokenA),
            address(tokenB),
            amountA,
            amountB
        );
    }

    // Swap TokenB -> TokenA
    function swapBForA(uint256 amountB) external {

        require(amountB > 0, "Invalid amount");

        uint256 amountA = amountB / rate;

        require(
            tokenA.balanceOf(address(this)) >= amountA,
            "Insufficient liquidity"
        );

        tokenB.transferFrom(
            msg.sender,
            address(this),
            amountB
        );

        tokenA.transfer(msg.sender, amountA);

        emit Swapped(
            msg.sender,
            address(tokenB),
            address(tokenA),
            amountB,
            amountA
        );
    }

    // Owner adds liquidity
    function addLiquidity(
        uint256 amountA,
        uint256 amountB
    ) external onlyOwner {

        tokenA.transferFrom(
            msg.sender,
            address(this),
            amountA
        );

        tokenB.transferFrom(
            msg.sender,
            address(this),
            amountB
        );
    }
}