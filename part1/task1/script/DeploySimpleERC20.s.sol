// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {SimpleERC20} from "../src/SimpleERC20.sol";

contract DeploySimpleERC20 is Script {
    function run() external returns (SimpleERC20 token) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        token = new SimpleERC20("Token", "TKN");
        vm.stopBroadcast();
    }
}
