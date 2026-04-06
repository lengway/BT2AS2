// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TestERC20} from "./TestERC20.sol";
import {LPToken} from "./LPToken.sol";

contract AMM {
    error InvalidToken();
    error ZeroAmount();
    error SlippageExceeded();
    error InsufficientLiquidityMinted();

    TestERC20 public immutable tokenA;
    TestERC20 public immutable tokenB;
    LPToken public immutable lpToken;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpMinted);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpBurned);
    event Swap(address indexed trader, address indexed tokenIn, uint256 amountIn, address indexed tokenOut, uint256 amountOut);

    constructor(address tokenAAddress, address tokenBAddress) {
        tokenA = TestERC20(tokenAAddress);
        tokenB = TestERC20(tokenBAddress);
        lpToken = new LPToken(address(this));
    }

    function addLiquidity(uint256 amountAIn, uint256 amountBIn, uint256 minLpOut)
        external
        returns (uint256 amountAUsed, uint256 amountBUsed, uint256 lpMinted)
    {
        if (amountAIn == 0 || amountBIn == 0) revert ZeroAmount();

        (uint256 reserveA, uint256 reserveB) = getReserves();
        uint256 totalLpSupply = lpToken.totalSupply();

        if (totalLpSupply == 0) {
            amountAUsed = amountAIn;
            amountBUsed = amountBIn;
            lpMinted = _sqrt(amountAUsed * amountBUsed);
        } else {
            uint256 amountBOptimal = (amountAIn * reserveB) / reserveA;
            if (amountBOptimal <= amountBIn) {
                amountAUsed = amountAIn;
                amountBUsed = amountBOptimal;
            } else {
                uint256 amountAOptimal = (amountBIn * reserveA) / reserveB;
                amountAUsed = amountAOptimal;
                amountBUsed = amountBIn;
            }

            lpMinted = _min((amountAUsed * totalLpSupply) / reserveA, (amountBUsed * totalLpSupply) / reserveB);
        }

        if (lpMinted == 0) revert InsufficientLiquidityMinted();
        if (lpMinted < minLpOut) revert SlippageExceeded();

        tokenA.transferFrom(msg.sender, address(this), amountAUsed);
        tokenB.transferFrom(msg.sender, address(this), amountBUsed);

        lpToken.mint(msg.sender, lpMinted);

        emit LiquidityAdded(msg.sender, amountAUsed, amountBUsed, lpMinted);
    }

    function removeLiquidity(uint256 lpAmount, uint256 minAmountAOut, uint256 minAmountBOut)
        external
        returns (uint256 amountAOut, uint256 amountBOut)
    {
        if (lpAmount == 0) revert ZeroAmount();

        uint256 totalLpSupply = lpToken.totalSupply();
        (uint256 reserveA, uint256 reserveB) = getReserves();

        amountAOut = (lpAmount * reserveA) / totalLpSupply;
        amountBOut = (lpAmount * reserveB) / totalLpSupply;

        if (amountAOut < minAmountAOut || amountBOut < minAmountBOut) revert SlippageExceeded();

        lpToken.burn(msg.sender, lpAmount);
        tokenA.transfer(msg.sender, amountAOut);
        tokenB.transfer(msg.sender, amountBOut);

        emit LiquidityRemoved(msg.sender, amountAOut, amountBOut, lpAmount);
    }

    function swap(address tokenIn, uint256 amountIn, uint256 minAmountOut)
        external
        returns (uint256 amountOut)
    {
        if (amountIn == 0) revert ZeroAmount();

        bool inIsTokenA = tokenIn == address(tokenA);
        if (!inIsTokenA && tokenIn != address(tokenB)) revert InvalidToken();

        (uint256 reserveA, uint256 reserveB) = getReserves();

        if (inIsTokenA) {
            amountOut = getAmountOut(amountIn, reserveA, reserveB);
            if (amountOut < minAmountOut) revert SlippageExceeded();

            tokenA.transferFrom(msg.sender, address(this), amountIn);
            tokenB.transfer(msg.sender, amountOut);

            emit Swap(msg.sender, address(tokenA), amountIn, address(tokenB), amountOut);
        } else {
            amountOut = getAmountOut(amountIn, reserveB, reserveA);
            if (amountOut < minAmountOut) revert SlippageExceeded();

            tokenB.transferFrom(msg.sender, address(this), amountIn);
            tokenA.transfer(msg.sender, amountOut);

            emit Swap(msg.sender, address(tokenB), amountIn, address(tokenA), amountOut);
        }
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256 amountOut) {
        if (amountIn == 0 || reserveIn == 0 || reserveOut == 0) revert ZeroAmount();

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function getReserves() public view returns (uint256 reserveA, uint256 reserveB) {
        reserveA = tokenA.balanceOf(address(this));
        reserveB = tokenB.balanceOf(address(this));
    }

    function _min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
