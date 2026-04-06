// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SimpleERC20} from "../../src/SimpleERC20.sol";

contract Handler is Test {
    SimpleERC20 internal immutable token;
    address[] internal users;

    constructor(SimpleERC20 _token, address[] memory seededUsers) {
        token = _token;
        for (uint256 i = 0; i < seededUsers.length; i++) {
            users.push(seededUsers[i]);
        }
    }

    function transferBetween(uint256 fromSeed, uint256 toSeed, uint96 amountRaw) external {
        address from = users[fromSeed % users.length];
        address to = users[toSeed % users.length];
        if (to == address(0) || from == to) return;

        uint256 balance = token.balanceOf(from);
        if (balance == 0) return;

        uint256 amount = uint256(amountRaw) % (balance + 1);

        if (amount == 0) return;

        vm.prank(from);
        token.transfer(to, amount);
    }
}
