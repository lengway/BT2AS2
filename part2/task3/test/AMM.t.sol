// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AMM} from "../src/AMM.sol";
import {TokenA} from "../src/TokenA.sol";
import {TokenB} from "../src/TokenB.sol";
import {LPToken} from "../src/LPToken.sol";

contract AMMTest is Test {
    TokenA internal tokenA;
    TokenB internal tokenB;
    AMM internal amm;
    LPToken internal lpToken;

    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    address internal carol = makeAddr("carol");

    function setUp() public {
        tokenA = new TokenA();
        tokenB = new TokenB();
        amm = new AMM(address(tokenA), address(tokenB));
        lpToken = amm.lpToken();

        tokenA.mint(alice, 1_000_000 ether);
        tokenB.mint(alice, 1_000_000 ether);
        tokenA.mint(bob, 1_000_000 ether);
        tokenB.mint(bob, 1_000_000 ether);
        tokenA.mint(carol, 1_000_000 ether);
        tokenB.mint(carol, 1_000_000 ether);

        vm.prank(alice);
        tokenA.approve(address(amm), type(uint256).max);
        vm.prank(alice);
        tokenB.approve(address(amm), type(uint256).max);

        vm.prank(bob);
        tokenA.approve(address(amm), type(uint256).max);
        vm.prank(bob);
        tokenB.approve(address(amm), type(uint256).max);

        vm.prank(carol);
        tokenA.approve(address(amm), type(uint256).max);
        vm.prank(carol);
        tokenB.approve(address(amm), type(uint256).max);
    }

    function testAddLiquidityFirstProviderMintsLP() public {
        vm.prank(alice);
        (, , uint256 lpMinted) = amm.addLiquidity(10_000 ether, 10_000 ether, 0);

        assertEq(lpMinted, 10_000 ether);
        assertEq(lpToken.balanceOf(alice), 10_000 ether);
    }

    function testAddLiquiditySubsequentProviderMintsProportionalLP() public {
        vm.prank(alice);
        amm.addLiquidity(10_000 ether, 10_000 ether, 0);

        vm.prank(bob);
        (, , uint256 lpMinted) = amm.addLiquidity(1_000 ether, 1_000 ether, 0);

        assertEq(lpMinted, 1_000 ether);
        assertEq(lpToken.balanceOf(bob), 1_000 ether);
    }

    function testAddLiquidityUsesOptimalRatio() public {
        vm.prank(alice);
        amm.addLiquidity(10_000 ether, 10_000 ether, 0);

        vm.prank(bob);
        (uint256 amountAUsed, uint256 amountBUsed,) = amm.addLiquidity(1_000 ether, 2_000 ether, 0);

        assertEq(amountAUsed, 1_000 ether);
        assertEq(amountBUsed, 1_000 ether);
    }

    function testAddLiquidityZeroAmountReverts() public {
        vm.prank(alice);
        vm.expectRevert(AMM.ZeroAmount.selector);
        amm.addLiquidity(0, 100 ether, 0);
    }

    function testAddLiquiditySingleSidedReverts() public {
        vm.prank(alice);
        vm.expectRevert(AMM.ZeroAmount.selector);
        amm.addLiquidity(100 ether, 0, 0);
    }

    function testRemoveLiquidityPartial() public {
        vm.prank(alice);
        amm.addLiquidity(10_000 ether, 10_000 ether, 0);

        vm.prank(alice);
        (uint256 amountAOut, uint256 amountBOut) = amm.removeLiquidity(5_000 ether, 0, 0);

        assertEq(amountAOut, 5_000 ether);
        assertEq(amountBOut, 5_000 ether);
        assertEq(lpToken.balanceOf(alice), 5_000 ether);
    }

    function testRemoveLiquidityFull() public {
        vm.prank(alice);
        amm.addLiquidity(10_000 ether, 10_000 ether, 0);

        vm.prank(alice);
        amm.removeLiquidity(10_000 ether, 0, 0);

        assertEq(lpToken.balanceOf(alice), 0);
        (uint256 reserveA, uint256 reserveB) = amm.getReserves();
        assertEq(reserveA, 0);
        assertEq(reserveB, 0);
    }

    function testRemoveLiquidityZeroReverts() public {
        vm.prank(alice);
        amm.addLiquidity(10_000 ether, 10_000 ether, 0);

        vm.prank(alice);
        vm.expectRevert(AMM.ZeroAmount.selector);
        amm.removeLiquidity(0, 0, 0);
    }

    function testRemoveLiquiditySlippageReverts() public {
        vm.prank(alice);
        amm.addLiquidity(10_000 ether, 10_000 ether, 0);

        vm.prank(alice);
        vm.expectRevert(AMM.SlippageExceeded.selector);
        amm.removeLiquidity(1_000 ether, 2_000 ether, 0);
    }

    function testSwapTokenAToTokenB() public {
        _seedPool();

        vm.prank(bob);
        uint256 out = amm.swap(address(tokenA), 100 ether, 1);

        assertGt(out, 0);
        assertEq(tokenA.balanceOf(address(amm)), 10_100 ether);
        assertEq(tokenB.balanceOf(bob), 1_000_000 ether + out);
    }

    function testSwapTokenBToTokenA() public {
        _seedPool();

        vm.prank(bob);
        uint256 out = amm.swap(address(tokenB), 100 ether, 1);

        assertGt(out, 0);
        assertEq(tokenB.balanceOf(address(amm)), 10_100 ether);
        assertEq(tokenA.balanceOf(bob), 1_000_000 ether + out);
    }

    function testSwapSlippageProtectionReverts() public {
        _seedPool();

        vm.prank(bob);
        vm.expectRevert(AMM.SlippageExceeded.selector);
        amm.swap(address(tokenA), 100 ether, 100_000 ether);
    }

    function testSwapZeroAmountReverts() public {
        _seedPool();

        vm.prank(bob);
        vm.expectRevert(AMM.ZeroAmount.selector);
        amm.swap(address(tokenA), 0, 0);
    }

    function testInvariantKDoesNotDecreaseAfterSwap() public {
        _seedPool();

        (uint256 reserveABefore, uint256 reserveBBefore) = amm.getReserves();
        uint256 kBefore = reserveABefore * reserveBBefore;

        vm.prank(bob);
        amm.swap(address(tokenA), 1_000 ether, 1);

        (uint256 reserveAAfter, uint256 reserveBAfter) = amm.getReserves();
        uint256 kAfter = reserveAAfter * reserveBAfter;
        assertGe(kAfter, kBefore);
    }

    function testLargeSwapHasHighPriceImpact() public {
        _seedPool();

        uint256 tinySwapOut = amm.getAmountOut(1 ether, 10_000 ether, 10_000 ether);
        uint256 largeSwapOut = amm.getAmountOut(5_000 ether, 10_000 ether, 10_000 ether);

        assertLt(largeSwapOut, tinySwapOut * 5_000);
    }

    function testGetAmountOutMatchesFormula() public view {
        uint256 out = amm.getAmountOut(100 ether, 10_000 ether, 10_000 ether);
        uint256 amountInWithFee = 100 ether * 997;
        uint256 numerator = amountInWithFee * 10_000 ether;
        uint256 denominator = 10_000 ether * 1000 + amountInWithFee;
        uint256 expected = numerator / denominator;
        assertEq(out, expected);
    }

    function testFuzzSwapAmountOutPositiveAndReservesUpdate(uint96 amountRaw) public {
        _seedPool();

        uint256 amountIn = uint256(amountRaw) % 1_000 ether + 1;
        (uint256 reserveABefore, uint256 reserveBBefore) = amm.getReserves();
        uint256 expectedOut = amm.getAmountOut(amountIn, reserveABefore, reserveBBefore);
        vm.assume(expectedOut > 0);

        vm.prank(carol);
        uint256 amountOut = amm.swap(address(tokenA), amountIn, 0);

        assertGt(amountOut, 0);

        (uint256 reserveAAfter, uint256 reserveBAfter) = amm.getReserves();
        assertEq(reserveAAfter, reserveABefore + amountIn);
        assertEq(reserveBAfter, reserveBBefore - amountOut);
    }

    function _seedPool() internal {
        vm.prank(alice);
        amm.addLiquidity(10_000 ether, 10_000 ether, 0);
    }
}
