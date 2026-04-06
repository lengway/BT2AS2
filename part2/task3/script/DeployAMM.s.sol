// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {TokenA} from "../src/TokenA.sol";
import {TokenB} from "../src/TokenB.sol";
import {AMM} from "../src/AMM.sol";

contract DeployAMM is Script {
    function run() external returns (TokenA tokenA, TokenB tokenB, AMM amm) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        tokenA = new TokenA();
        tokenB = new TokenB();
        amm = new AMM(address(tokenA), address(tokenB));
        vm.stopBroadcast();
    }
}
