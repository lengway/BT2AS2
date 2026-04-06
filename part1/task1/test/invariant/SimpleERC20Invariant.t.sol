// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";
import {SimpleERC20} from "../../src/SimpleERC20.sol";
import {Handler} from "./Handler.t.sol";

contract SimpleERC20InvariantTest is StdInvariant, Test {
    SimpleERC20 internal token;
    Handler internal handler;

    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    address internal charlie = makeAddr("charlie");

    function setUp() public {
        token = new SimpleERC20("Token", "TKN");

        token.mint(alice, 1_000 ether);
        token.mint(bob, 700 ether);
        token.mint(charlie, 300 ether);

        address[] memory users = new address[](3);
        users[0] = alice;
        users[1] = bob;
        users[2] = charlie;

        handler = new Handler(token, users);
        targetContract(address(handler));
    }

    function invariant_totalSupplyRemainsConstantAfterTransfers() public view {
        assertEq(token.totalSupply(), 2_000 ether);
    }

    function invariant_noHolderExceedsTotalSupply() public view {
        assertLe(token.balanceOf(alice), token.totalSupply());
        assertLe(token.balanceOf(bob), token.totalSupply());
        assertLe(token.balanceOf(charlie), token.totalSupply());
    }
}
