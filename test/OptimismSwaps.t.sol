//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/CrossChainSwaps/Chains/Optimism/OptimismSwaps.sol";
import "../src/CrossChainSwaps/FeeCollector.sol";
import "../src/CrossChainSwaps/adapters/VelodromeAdapter.sol";

contract OptimismTest is Test {
    OptimismSwaps swaps;
    FeeCollector feeCollector;
    uint256 amount = 10 ether;

    function setUp() public {
        feeCollector = new FeeCollector();
        swaps = new OptimismSwaps(
            IWETH9(0x4200000000000000000000000000000000000006),
            address(feeCollector),
            ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564),
            address(0x0000000000000000000000000000000000000000),
            bytes32(0x0000000000000000000000000000000000000000000000000000000000000000),
            IStargateRouter(0xB0D502E938ed5f4df2E681fE6E419ff29631d62b)
        );
    }

    function testVelo() public {
        uint8[] memory steps = new uint8[](2);
        steps[0] = 2;
        steps[1] = 9;
        //steps[1] = 11;

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encode(amount);

        VelodromeAdapter.route[] memory routes = new VelodromeAdapter.route[](1);
        routes[0] = VelodromeAdapter.route(
            address(0x4200000000000000000000000000000000000006),
            address(0x7F5c764cBc14f9669B88837ca1490cCa17c31607),
            false
        );

        /**
         *  XCaliburAdapter.XcaliburParams[] memory params = new XCaliburAdapter.XcaliburParams[](1);
            XCaliburAdapter.route[] memory routes = new XCaliburAdapter.route[](2);
            routes[0] = XCaliburAdapter.route(weth, usdc, false);
            routes[1] = XCaliburAdapter.route(usdc, xcal, false);
            params[0] = XCaliburAdapter.XcaliburParams(amount, 0, routes, block.timestamp);
         */

        VelodromeAdapter.VeloParams[] memory veloParams = new VelodromeAdapter.VeloParams[](1);
        veloParams[0] = VelodromeAdapter.VeloParams(amount, 10e9, routes, block.timestamp);
        data[1] = abi.encode(veloParams);

        swaps.optimismSwaps{value: amount}(steps, data);
        assertEq(IERC20(0x4200000000000000000000000000000000000006).balanceOf(address(swaps)), 0 ether);
    }
}
