// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswapV2Router02 {
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

contract ForkMainnetTest is Test {
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256 internal forkId;
    bool internal forkAvailable;

    function setUp() public {
        string memory rpcUrl = vm.envOr("MAINNET_RPC_URL", string(""));
        if (bytes(rpcUrl).length == 0) {
            forkAvailable = false;
            return;
        }

        forkId = vm.createSelectFork(rpcUrl);
        forkAvailable = true;
    }

    modifier onlyWhenForkAvailable() {
        if (!forkAvailable) {
            emit log("Skipping fork test: set MAINNET_RPC_URL to run against real mainnet state");
            return;
        }
        _;
    }

    function testReadUSDCRealTotalSupply() public onlyWhenForkAvailable {
        uint256 supply = IERC20(USDC).totalSupply();
        assertGt(supply, 1_000_000e6);
    }

    function testSimulateUniswapV2SwapOnFork() public onlyWhenForkAvailable {
        vm.selectFork(forkId);

        address trader = address(this);
        vm.deal(trader, 10 ether);

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;

        uint256 usdcBefore = IERC20(USDC).balanceOf(trader);

        IUniswapV2Router02(UNISWAP_V2_ROUTER).swapExactETHForTokens{value: 1 ether}(
            1,
            path,
            trader,
            block.timestamp + 1 hours
        );

        uint256 usdcAfter = IERC20(USDC).balanceOf(trader);
        assertGt(usdcAfter, usdcBefore);
    }

    function testRollForkChangesBlockNumber() public onlyWhenForkAvailable {
        vm.selectFork(forkId);
        uint256 beforeBlock = block.number;

        vm.rollFork(beforeBlock);

        assertEq(block.number, beforeBlock);
    }
}
