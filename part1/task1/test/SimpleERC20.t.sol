// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SimpleERC20} from "../src/SimpleERC20.sol";

contract SimpleERC20Test is Test {
    SimpleERC20 internal token;
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    address internal charlie = makeAddr("charlie");

    function setUp() public {
        token = new SimpleERC20("Token", "TKN");
        token.mint(alice, 1_000 ether);
        token.mint(bob, 500 ether);
    }

    function testMintIncreasesTotalSupplyAndBalance() public {
        uint256 supplyBefore = token.totalSupply();
        token.mint(charlie, 250 ether);
        assertEq(token.totalSupply(), supplyBefore + 250 ether);
        assertEq(token.balanceOf(charlie), 250 ether);
    }

    function testMintToZeroReverts() public {
        vm.expectRevert(SimpleERC20.ZeroAddress.selector);
        token.mint(address(0), 1 ether);
    }

    function testTransferMovesBalance() public {
        vm.prank(alice);
        token.transfer(bob, 100 ether);
        assertEq(token.balanceOf(alice), 900 ether);
        assertEq(token.balanceOf(bob), 600 ether);
    }

    function testTransferZeroAmountIsNoopButValid() public {
        vm.prank(alice);
        token.transfer(bob, 0);
        assertEq(token.balanceOf(alice), 1_000 ether);
        assertEq(token.balanceOf(bob), 500 ether);
    }

    function testTransferInsufficientBalanceReverts() public {
        vm.prank(charlie);
        vm.expectRevert(SimpleERC20.InsufficientBalance.selector);
        token.transfer(alice, 1);
    }

    function testTransferToZeroReverts() public {
        vm.prank(alice);
        vm.expectRevert(SimpleERC20.ZeroAddress.selector);
        token.transfer(address(0), 1 ether);
    }

    function testApproveSetsAllowance() public {
        vm.prank(alice);
        token.approve(charlie, 123 ether);
        assertEq(token.allowance(alice, charlie), 123 ether);
    }

    function testApproveZeroAddressReverts() public {
        vm.prank(alice);
        vm.expectRevert(SimpleERC20.ZeroAddress.selector);
        token.approve(address(0), 1 ether);
    }

    function testTransferFromUsesAllowance() public {
        vm.startPrank(alice);
        token.approve(charlie, 300 ether);
        vm.stopPrank();

        vm.prank(charlie);
        token.transferFrom(alice, bob, 120 ether);

        assertEq(token.balanceOf(alice), 880 ether);
        assertEq(token.balanceOf(bob), 620 ether);
        assertEq(token.allowance(alice, charlie), 180 ether);
    }

    function testTransferFromInsufficientAllowanceReverts() public {
        vm.startPrank(alice);
        token.approve(charlie, 10 ether);
        vm.stopPrank();

        vm.prank(charlie);
        vm.expectRevert(SimpleERC20.InsufficientAllowance.selector);
        token.transferFrom(alice, bob, 11 ether);
    }

    function testTransferFromInsufficientBalanceReverts() public {
        vm.startPrank(charlie);
        token.approve(alice, 100 ether);
        vm.stopPrank();

        vm.prank(alice);
        vm.expectRevert(SimpleERC20.InsufficientBalance.selector);
        token.transferFrom(charlie, bob, 1 ether);
    }

    function testTransferFromToZeroReverts() public {
        vm.startPrank(alice);
        token.approve(charlie, 1 ether);
        vm.stopPrank();

        vm.prank(charlie);
        vm.expectRevert(SimpleERC20.ZeroAddress.selector);
        token.transferFrom(alice, address(0), 1 ether);
    }

    function testFuzzTransfer(address recipient, uint96 amountRaw) public {
        vm.assume(recipient != address(0));
        uint256 amount = uint256(amountRaw) % (token.balanceOf(alice) + 1);

        uint256 aliceBefore = token.balanceOf(alice);
        uint256 recipientBefore = token.balanceOf(recipient);

        vm.prank(alice);
        token.transfer(recipient, amount);

        if (recipient == alice) {
            assertEq(token.balanceOf(alice), aliceBefore);
            return;
        }

        assertEq(token.balanceOf(alice), aliceBefore - amount);
        assertEq(token.balanceOf(recipient), recipientBefore + amount);
    }
}
