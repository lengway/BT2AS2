// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TestERC20} from "./TestERC20.sol";

contract TokenB is TestERC20 {
    constructor() TestERC20("Token B", "TKB") {}
}
