// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/StargateTestor.sol";

//Start by simplyfiying the code and getting it to work from there
// Mint USDC

contract StargateTestorTest is Test {
    StargateTestor stgTest;
    address USDCwhale = address(0x8156b28cA956C3a8BAb86e1D38D8648d58CD23ec);

    function setUp() public {
        stgTest = new StargateTestor(
            IStargateRouter(0x8731d54E9D02c286767d56ac03e8037C07e01e98)
        );
    }

    function testTestingSwap() public {
        StargateTestor.StargateParams memory params = StargateTestor
            .StargateParams(
                106,
                0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
                1,
                1,
                100e6,
                0,
                1e17,
                address(this),
                address(this),
                1e17,
                bytes32("0x00")
            );
        vm.startPrank(USDCwhale);
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).approve(
            address(stgTest),
            type(uint256).max
        );
        uint256 amount = 1e18;
        stgTest.stargateSwap{value: amount}(params);
    }
}
