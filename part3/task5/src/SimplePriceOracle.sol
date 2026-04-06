// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SimplePriceOracle {
    uint256 public priceCollateralInDebt = 1e18;

    function setPrice(uint256 newPrice) external {
        priceCollateralInDebt = newPrice;
    }
}
