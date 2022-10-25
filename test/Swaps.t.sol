// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CrossChainSwaps/CrossChainSwaps.sol";
import "../src/mocks/MockERC20.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/CrossChainSwaps/adapters/StargateAdapter.sol";

contract SwapsTest is Test {
    CrossChainSwaps swaps;
    CrossChainSwaps ethSwaps;
    CrossChainSwaps bnbSwaps;
    CrossChainSwaps avaxSwaps;
    address USDCEth = address(0x00F6527D16B5234Ccc8EF966c6d3DC616B6A7F75);

    function setUp() public {
        // swaps = new CrossChainSwaps(
        //     address(0x4200000000000000000000000000000000000006),
        //     ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564),
        //     0x0000000000000000000000000000000000000000,
        //     0x0000000000000000000000000000000000000000000000000000000000000000,
        //     0x25CbdDb98b35ab1FF77413456B31EC81A6B6B746,
        //     address(0x4200000000000000000000000000000000000006),
        //     IStargateRouter(0xB0D502E938ed5f4df2E681fE6E419ff29631d62b)
        // ); //Optimism Set Up
        ethSwaps = new CrossChainSwaps(
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2),
            ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564),
            0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac,
            0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            IStargateRouter(0x8731d54E9D02c286767d56ac03e8037C07e01e98)
        ); //ETH Setup
        bnbSwaps = new CrossChainSwaps(
            address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c),
            ISwapRouter(0x0000000000000000000000000000000000000000),
            0xc35DADB65012eC5796536bD9864eD8773aBc74C4,
            0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            IStargateRouter(0x4a364f8c717cAAD9A442737Eb7b8A55cc6cf18D8)
        ); //BNB Setup
        avaxSwaps = new CrossChainSwaps(
            address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7),
            ISwapRouter(0x0000000000000000000000000000000000000000),
            0xc35DADB65012eC5796536bD9864eD8773aBc74C4,
            0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            IStargateRouter(0x45A01E4e04F14f7A4a6702c74187c5F6222033cd)
        ); // Avax Setup
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

    // function testVelo() public returns (uint256 balance) {
    //     uint256 time = block.timestamp + 1 days;
    //     VelodromeAdapter.route[] memory routes = new VelodromeAdapter.route[](
    //         1
    //     );
    //     routes[0].from = address(0x4200000000000000000000000000000000000006);
    //     routes[0].to = address(0x7F5c764cBc14f9669B88837ca1490cCa17c31607);
    //     routes[0].stable = false;
    //     uint8[] memory steps = new uint8[](3);
    //     bytes[] memory data = new bytes[](3);
    //     steps[0] = 2;
    //     steps[1] = 9;
    //     steps[2] = 10;
    //     data[0] = abi.encode(10 ether);
    //     data[1] = abi.encode(9 ether, 13345094, routes, address(swaps), time);
    //     uint8[] memory steped = new uint8[](1);
    //     bytes[] memory datas = new bytes[](1);
    //     steped[0] = 1;
    //     datas[0] = abi.encode(10 ether);
    //     StargateAdapter.StargateParams memory params = StargateAdapter
    //         .StargateParams(
    //             101,
    //             0x7F5c764cBc14f9669B88837ca1490cCa17c31607,
    //             1,
    //             1,
    //             0,
    //             0,
    //             0,
    //             0x6Cb6D9Fb673CfbF31b3A432F6316fE3196efd4aA,
    //             0x6Cb6D9Fb673CfbF31b3A432F6316fE3196efd4aA,
    //             200000,
    //             bytes32("test")
    //         );
    //     data[2] = abi.encode(params, steped, datas);
    //     swaps.swaps{value: 11 ether}(steps, data);
    //     balance = IERC20(address(0x7F5c764cBc14f9669B88837ca1490cCa17c31607))
    //         .balanceOf(address(swaps));
    //     assertEq(balance, 0);
    //     assertEq(
    //         IERC20(address(0x7F5c764cBc14f9669B88837ca1490cCa17c31607))
    //             .balanceOf(address(this)),
    //         0
    //     );
    // } //Approval Function, amounts autofill

    function testUniAndSushiETH() public {
        vm.startPrank(USDCEth);
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).transfer(
            address(this),
            10000000e6
        );
        vm.stopPrank();
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).approve(
            address(ethSwaps),
            type(uint256).max
        );
        bytes[] memory data = new bytes[](3);
        uint8[] memory steps = new uint8[](3);
        steps[0] = 1;
        steps[1] = 4;
        steps[2] = 10;
        data[0] = abi.encode(
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            10000e6
        );
        data[1] = abi.encode(
            0,
            0,
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            500,
            500,
            address(ethSwaps)
        );
        StargateAdapter.StargateParams memory params = StargateAdapter
            .StargateParams(
                109,
                0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
                1,
                1,
                0,
                0,
                1e10,
                0x6Cb6D9Fb673CfbF31b3A432F6316fE3196efd4aA,
                0x6Cb6D9Fb673CfbF31b3A432F6316fE3196efd4aA,
                200000,
                bytes32("test")
            );
        uint8[] memory step = new uint8[](1);
        bytes[] memory datas = new bytes[](1);
        step[0] = 1;
        datas[0] = abi.encode(10 ether);
        data[2] = abi.encode(params, step, datas);
        ethSwaps.swaps{value: 1 ether}(steps, data);

        // |=================================================|
        // |=================================================|
        // |=================================================|

        bytes[] memory data2 = new bytes[](2);
        uint8[] memory steps2 = new uint8[](2);
        steps2[0] = 1;
        steps2[1] = 5;
        //steps2[2] = 10;
        data2[0] = abi.encode(
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            10000e6
        );
        address[] memory path = new address[](2);
        path[0] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        path[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        data2[1] = abi.encode(0, 10, path, address(ethSwaps), true);
        //data2[2] = abi.encode(params, step, datas);
        ethSwaps.swaps(steps2, data2);
        assertGt(
            IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).balanceOf(
                address(ethSwaps)
            ),
            65e17
        );
    }

    function testBNB() public {
        uint256 time = block.timestamp + 10 days;
        uint8[] memory steps = new uint8[](3);
        bytes[] memory data = new bytes[](3);
        address[] memory path = new address[](2);
        path[0] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        path[1] = 0x55d398326f99059fF775485246999027B3197955;
        steps[0] = 2;
        steps[1] = 7;
        steps[2] = 10;
        data[0] = abi.encode(10 ether);
        data[1] = abi.encode(9e18, 0, path, address(bnbSwaps), time);
        StargateAdapter.StargateParams memory params = StargateAdapter
            .StargateParams(
                109,
                0x55d398326f99059fF775485246999027B3197955,
                2,
                2,
                0,
                0,
                1e10,
                0x6Cb6D9Fb673CfbF31b3A432F6316fE3196efd4aA,
                0x6Cb6D9Fb673CfbF31b3A432F6316fE3196efd4aA,
                200000,
                bytes32("test")
            );
        uint8[] memory step = new uint8[](1);
        bytes[] memory datas = new bytes[](1);
        step[0] = 1;
        datas[0] = abi.encode(10 ether);
        data[2] = abi.encode(params, step, datas);
        bnbSwaps.swaps{value: 11 ether}(steps, data);
    }

    function testAvax() public {
        uint8[] memory steps = new uint8[](3);
        bytes[] memory data = new bytes[](3);
        steps[0] = 2;
        steps[1] = 6;
        steps[2] = 10;
    }

    function testFantom() public {}
}
