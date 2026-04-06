// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {CollateralToken} from "../src/CollateralToken.sol";
import {DebtToken} from "../src/DebtToken.sol";
import {SimplePriceOracle} from "../src/SimplePriceOracle.sol";

contract LendingPoolTest is Test {
    CollateralToken internal collateral;
    DebtToken internal debt;
    SimplePriceOracle internal oracle;
    LendingPool internal pool;

    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function setUp() public {
        collateral = new CollateralToken();
        debt = new DebtToken();
        oracle = new SimplePriceOracle();
        pool = new LendingPool(address(collateral), address(debt), address(oracle));

        collateral.mint(alice, 1_000_000 ether);
        debt.mint(alice, 1_000_000 ether);
        debt.mint(bob, 1_000_000 ether);
        debt.mint(address(pool), 1_000_000 ether);

        vm.prank(alice);
        collateral.approve(address(pool), type(uint256).max);
        vm.prank(alice);
        debt.approve(address(pool), type(uint256).max);

        vm.prank(bob);
        debt.approve(address(pool), type(uint256).max);
    }

    function testDepositUpdatesPosition() public {
        vm.prank(alice);
        pool.deposit(1_000 ether);

        (uint256 deposited,,) = pool.positions(alice);
        assertEq(deposited, 1_000 ether);
    }

    function testWithdrawAfterDepositNoDebt() public {
        vm.startPrank(alice);
        pool.deposit(1_000 ether);
        pool.withdraw(400 ether);
        vm.stopPrank();

        (uint256 deposited,,) = pool.positions(alice);
        assertEq(deposited, 600 ether);
    }

    function testBorrowWithinLtvSucceeds() public {
        vm.startPrank(alice);
        pool.deposit(1_000 ether);
        pool.borrow(700 ether);
        vm.stopPrank();

        (,uint256 borrowed,) = pool.positions(alice);
        assertEq(borrowed, 700 ether);
    }

    function testBorrowExceedingLtvReverts() public {
        vm.startPrank(alice);
        pool.deposit(1_000 ether);
        vm.expectRevert(LendingPool.ExceedsLtv.selector);
        pool.borrow(800 ether);
        vm.stopPrank();
    }

    function testRepayPartial() public {
        vm.startPrank(alice);
        pool.deposit(1_000 ether);
        pool.borrow(700 ether);
        pool.repay(200 ether);
        vm.stopPrank();

        (,uint256 borrowed,) = pool.positions(alice);
        assertEq(borrowed, 500 ether);
    }

    function testRepayFull() public {
        vm.startPrank(alice);
        pool.deposit(1_000 ether);
        pool.borrow(700 ether);
        pool.repay(type(uint256).max);
        vm.stopPrank();

        (,uint256 borrowed,) = pool.positions(alice);
        assertEq(borrowed, 0);
    }

    function testBorrowWithZeroCollateralReverts() public {
        vm.prank(alice);
        vm.expectRevert(LendingPool.ExceedsLtv.selector);
        pool.borrow(1 ether);
    }

    function testWithdrawWithOutstandingDebtRevertsWhenUnhealthy() public {
        vm.startPrank(alice);
        pool.deposit(1_000 ether);
        pool.borrow(700 ether);
        vm.expectRevert(LendingPool.ExceedsLtv.selector);
        pool.withdraw(200 ether);
        vm.stopPrank();
    }

    function testLiquidationAfterPriceDropWorks() public {
        vm.startPrank(alice);
        pool.deposit(1_000 ether);
        pool.borrow(700 ether);
        vm.stopPrank();

        oracle.setPrice(0.8e18);

        vm.prank(bob);
        pool.liquidate(alice);

        (uint256 deposited,uint256 borrowed,) = pool.positions(alice);
        assertEq(deposited, 0);
        assertEq(borrowed, 0);
        assertEq(collateral.balanceOf(bob), 1_000 ether);
    }

    function testInterestAccrualOverTimeWithWarp() public {
        vm.startPrank(alice);
        pool.deposit(1_000 ether);
        pool.borrow(700 ether);
        vm.warp(block.timestamp + 365 days);
        uint256 projected = pool.getProjectedBorrowed(alice);
        vm.stopPrank();

        assertGt(projected, 700 ether);
    }

    function testHealthFactorAboveOneForHealthyPosition() public {
        vm.startPrank(alice);
        pool.deposit(1_000 ether);
        pool.borrow(500 ether);
        vm.stopPrank();

        uint256 hf = pool.getHealthFactor(alice);
        assertGt(hf, 1e18);
    }
}
