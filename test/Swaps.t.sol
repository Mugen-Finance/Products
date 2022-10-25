// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CrossChainSwaps/CrossChainSwaps.sol";
import "../src/mocks/MockERC20.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/CrossChainSwaps/adapters/StargateAdapter.sol";

contract SwapsTest is Test {
    CrossChainSwaps swaps;

    function setUp() public {
        swaps = new CrossChainSwaps(
            address(0x4200000000000000000000000000000000000006),
            ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564),
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000000000000000000000000000,
            0x25CbdDb98b35ab1FF77413456B31EC81A6B6B746,
            address(0x4200000000000000000000000000000000000006),
            IStargateRouter(0xB0D502E938ed5f4df2E681fE6E419ff29631d62b)
        ); //Optimism Set Up
    }

    function testSetUp() public {
        assertEq(swaps.feeCollector(), address(this));
    }

    function testFee() public returns (uint256 balance) {
        uint8[] memory steps = new uint8[](1);
        bytes[] memory data = new bytes[](1);
        steps[0] = 2;
        data[0] = abi.encode(10 ether);
        swaps.swaps{value: 10 ether}(steps, data);
        balance = IERC20(address(0x4200000000000000000000000000000000000006))
            .balanceOf(address(swaps));
    } // Need to fix the fee calculation

    function testVelo() public returns (uint256 balance) {
        uint256 time = block.timestamp + 1 days;
        VelodromeAdapter.route[] memory routes = new VelodromeAdapter.route[](
            1
        );
        routes[0].from = address(0x4200000000000000000000000000000000000006);
        routes[0].to = address(0x7F5c764cBc14f9669B88837ca1490cCa17c31607);
        routes[0].stable = false;
        uint8[] memory steps = new uint8[](3);
        bytes[] memory data = new bytes[](3);
        steps[0] = 2;
        steps[1] = 9;
        steps[2] = 10;
        data[0] = abi.encode(10 ether);
        data[1] = abi.encode(9 ether, 13345094, routes, address(swaps), time);
        uint8[] memory steped = new uint8[](1);
        bytes[] memory datas = new bytes[](1);
        steped[0] = 1;
        datas[0] = abi.encode(10 ether);
        StargateAdapter.StargateParams memory params = StargateAdapter
            .StargateParams(
                101,
                0x7F5c764cBc14f9669B88837ca1490cCa17c31607,
                1,
                1,
                0,
                0,
                0,
                0x6Cb6D9Fb673CfbF31b3A432F6316fE3196efd4aA,
                0x6Cb6D9Fb673CfbF31b3A432F6316fE3196efd4aA,
                200000,
                bytes32("wergwer")
            );
        data[2] = abi.encode(params, steped, datas);
        swaps.swaps{value: 11 ether}(steps, data);
        balance = IERC20(0x7F5c764cBc14f9669B88837ca1490cCa17c31607).balanceOf(
            address(swaps)
        );
        assertEq(balance, 0);
    } //Approval Function, amounts autofill
}
