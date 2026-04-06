// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {CollateralToken} from "../src/CollateralToken.sol";
import {DebtToken} from "../src/DebtToken.sol";
import {SimplePriceOracle} from "../src/SimplePriceOracle.sol";
import {LendingPool} from "../src/LendingPool.sol";

contract DeployLendingPool is Script {
    function run()
        external
        returns (CollateralToken collateral, DebtToken debt, SimplePriceOracle oracle, LendingPool pool)
    {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        collateral = new CollateralToken();
        debt = new DebtToken();
        oracle = new SimplePriceOracle();
        pool = new LendingPool(address(collateral), address(debt), address(oracle));
        vm.stopBroadcast();
    }
}
