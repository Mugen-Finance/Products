// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CrossChainSwaps/CrossChainSwaps.sol";
import "../src/mocks/MockERC20.sol";
import "../src/CrossChainSwaps/adapters/StargateAdapter.sol";
import "../src/CrossChainSwaps/adapters/VelodromeAdapter.sol";
import "../src/CrossChainSwaps/adapters/UniswapAdapter.sol";

//Fork Tests
// Test paths
/**
Single to single
Multi to single
Single to multi
multi to multi
 */

contract SwapsUnitTest is Test {
    CrossChainSwaps swaps;
    CrossChainSwaps avax;
    MockERC20 token1;
    MockERC20 token2;
    MockERC20 token3;
    address alice = address(0x124);

    function setUp() public {
        // swaps = new CrossChainSwaps( //Optimism Setup
        //     address(0x4200000000000000000000000000000000000006),
        //     ISwapRouter(address(0xE592427A0AEce92De3Edee1F18E0157C05861564)),
        //     0x0000000000000000000000000000000000000000,
        //     0x0000000000000000000000000000000000000000000000000000000000000000,
        //     0x25CbdDb98b35ab1FF77413456B31EC81A6B6B746,
        //     address(0x4200000000000000000000000000000000000006),
        //     IStargateRouter(address(0xB0D502E938ed5f4df2E681fE6E419ff29631d62b))
        // );
        avax = new CrossChainSwaps(
            address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7), 
            ISwapRouter(address(0)), 
            address(0xc35DADB65012eC5796536bD9864eD8773aBc74C4), 
            bytes32(0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303), 
            address(0x25CbdDb98b35ab1FF77413456B31EC81A6B6B746), 
            address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7), 
            IStargateRouter(address(0x45A01E4e04F14f7A4a6702c74187c5F6222033cd))
        );
        // token1 = new MockERC20(
        //     "Token 1",
        //     "TK1",
        //     address(this),
        //     type(uint256).max
        // );
        // token2 = new MockERC20(
        //     "Token 2",
        //     "TK2",
        //     address(this),
        //     type(uint256).max
        // );
        // token3 = new MockERC20(
        //     "Token 3",
        //     "TK3",
        //     address(this),
        //     type(uint256).max
        // );
    }

    // function testOptimismExchangeVelo() public {
    //     uint256 time = block.timestamp + 20 days;
    //     uint8[] memory steps = new uint8[](3);
    //     steps[0] = 2;
    //     steps[1] = 9;
    //     steps[2] = 10;
    //     //-------------------------------------------------------------------
    //     //-------------------------------------------------------------------
    //     VelodromeAdapter.route[] memory routes = new VelodromeAdapter.route[](
    //         1
    //     );
    //     routes[0] = VelodromeAdapter.route(
    //         0x4200000000000000000000000000000000000006,
    //         0x7F5c764cBc14f9669B88837ca1490cCa17c31607,
    //         false
    //     );
    //     VelodromeAdapter.VeloParams[]
    //         memory velo = new VelodromeAdapter.VeloParams[](1);
    //     velo[0] = VelodromeAdapter.VeloParams(10 ether, 0, routes, time);
    //     //-------------------------------------------------------------------
    //     //-------------------------------------------------------------------
    //     CrossChainSwaps.SrcTransferParams[]
    //         memory srcTransfer = new CrossChainSwaps.SrcTransferParams[](1);

    //     srcTransfer[0] = CrossChainSwaps.SrcTransferParams(
    //         address(0x7F5c764cBc14f9669B88837ca1490cCa17c31607),
    //         address(this),
    //         0
    //     );
    //     //-------------------------------------------------------------------
    //     //-------------------------------------------------------------------
    //     bytes[] memory data = new bytes[](3);
    //     data[0] = abi.encode(10 ether);
    //     data[1] = abi.encode(velo);
    //     data[2] = abi.encode(srcTransfer);
    //     //-------------------------------------------------------------------
    //     //-------------------------------------------------------------------
    //     swaps.swaps{value: 10 ether}(steps, data);
    //     assertGt(
    //         IERC20(0x7F5c764cBc14f9669B88837ca1490cCa17c31607).balanceOf(
    //             address(this)
    //         ),
    //         14000e6
    //     );
    // }

    // //From WETH to USDC on optimism using Uniswap V3 Single Hop
    // function testOptimismSingleToSingle() public {
    //     uint256 time = block.timestamp + 20 days;
    //     uint8[] memory steps = new uint8[](3);
    //     steps[0] = 2;
    //     steps[1] = 3;
    //     steps[2] = 10;
    //     UniswapAdapter.UniswapV3Single[] memory uniswap = new UniswapAdapter.UniswapV3Single[](1);
    //     uniswap[0] = UniswapAdapter.UniswapV3Single(10 ether,0x4200000000000000000000000000000000000006, 0x7F5c764cBc14f9669B88837ca1490cCa17c31607, 500);
    //     CrossChainSwaps.SrcTransferParams[] memory srcTransfer = new CrossChainSwaps.SrcTransferParams[](1);
    //     srcTransfer[0] = CrossChainSwaps.SrcTransferParams(address(0x7F5c764cBc14f9669B88837ca1490cCa17c31607), address(this), 0);
    //     bytes[] memory data = new bytes[](3);
    //     data[0] = abi.encode(10 ether);
    //     data[1] = abi.encode(uniswap);
    //     data[2] = abi.encode(srcTransfer);
    //     swaps.swaps{value: 10 ether}(steps, data);
    //     assertGt(IERC20(0x7F5c764cBc14f9669B88837ca1490cCa17c31607).balanceOf(address(this)), 14000e6);
    // }

    // // From Weth to USDC and Dai on optimism using uniswap V3 Single Hop
    // function testOptimismSingleToMulti() public {
    //     uint8[] memory steps = new uint8[](3);
    //     steps[0] = 2;
    //     steps[1] = 3;
    //     steps[2] = 10;
    //     UniswapAdapter.UniswapV3Single[] memory uniswap = new UniswapAdapter.UniswapV3Single[](2);
    //     uniswap[0] = UniswapAdapter.UniswapV3Single(5 ether,0x4200000000000000000000000000000000000006, 0x7F5c764cBc14f9669B88837ca1490cCa17c31607, 500);
    //     uniswap[1] = UniswapAdapter.UniswapV3Single(5 ether,0x4200000000000000000000000000000000000006, 0x4200000000000000000000000000000000000042, 500);
    //     CrossChainSwaps.SrcTransferParams[] memory srcTransfer = new CrossChainSwaps.SrcTransferParams[](2);
    //     srcTransfer[0] = CrossChainSwaps.SrcTransferParams(address(0x7F5c764cBc14f9669B88837ca1490cCa17c31607), address(this), 0);
    //     srcTransfer[1] = CrossChainSwaps.SrcTransferParams(address(0x4200000000000000000000000000000000000042), address(this), 0);
    //     bytes[] memory data = new bytes[](3);
    //     data[0] = abi.encode(10 ether);
    //     data[1] = abi.encode(uniswap);
    //     data[2] = abi.encode(srcTransfer);
    //     swaps.swaps{value: 10 ether}(steps, data);
    //     assertGt(IERC20(0x4200000000000000000000000000000000000042).balanceOf(address(this)), 3000e18);
    //     assertGt(IERC20(0x7F5c764cBc14f9669B88837ca1490cCa17c31607).balanceOf(address(this)), 7000e6);

    // }

    // function testOptimismSingleToSingleMultiHop() public {
    //     uint8[] memory steps = new uint8[](3);
    //     steps[0] = 2;
    //     steps[1] = 4;
    //     steps[2] = 10;
    //     UniswapAdapter.UniswapV3Multi[] memory multi = new UniswapAdapter.UniswapV3Multi[](1);
    //     multi[0] = UniswapAdapter.UniswapV3Multi(10 ether, 0, 0x4200000000000000000000000000000000000006, 0x7F5c764cBc14f9669B88837ca1490cCa17c31607, 0x4200000000000000000000000000000000000042, 500, 3000);
    //     CrossChainSwaps.SrcTransferParams[] memory srcTransfer = new CrossChainSwaps.SrcTransferParams[](1);
    //     srcTransfer[0] = CrossChainSwaps.SrcTransferParams(address(0x4200000000000000000000000000000000000042), address(this), 0);
    //      bytes[] memory data = new bytes[](3);
    //     data[0] = abi.encode(10 ether);
    //     data[1] = abi.encode(multi);
    //     data[2] = abi.encode(srcTransfer);
    //     swaps.swaps{value: 10 ether}(steps, data);
    //      assertGt(IERC20(0x4200000000000000000000000000000000000042).balanceOf(address(this)), 10000e18);
    // }
    // function testOptimismMultiToSingleMultiHop() public {
    //     uint8[] memory steps = new uint8[](3);
    //     steps[0] = 2;
    //     steps[1] = 4;
    //     steps[2] = 10;
    //     UniswapAdapter.UniswapV3Multi[] memory multi = new UniswapAdapter.UniswapV3Multi[](2);
    //     multi[0] = UniswapAdapter.UniswapV3Multi(10 ether, 0, 0x4200000000000000000000000000000000000006, 0x7F5c764cBc14f9669B88837ca1490cCa17c31607, 0x4200000000000000000000000000000000000042, 500, 3000);
    //     multi[1] = UniswapAdapter.UniswapV3Multi(12000 ether, 0, 0x4200000000000000000000000000000000000042, 0x4200000000000000000000000000000000000006, 0x7F5c764cBc14f9669B88837ca1490cCa17c31607, 3000, 500);
    //     CrossChainSwaps.SrcTransferParams[] memory srcTransfer = new CrossChainSwaps.SrcTransferParams[](1);
    //     srcTransfer[0] = CrossChainSwaps.SrcTransferParams(address(0x7F5c764cBc14f9669B88837ca1490cCa17c31607), address(this), 0);
    //     bytes[] memory data = new bytes[](3);
    //     data[0] = abi.encode(10 ether);
    //     data[1] = abi.encode(multi);
    //     data[2] = abi.encode(srcTransfer);
    //     swaps.swaps{value: 10 ether}(steps, data);
    //     assertGt(IERC20(0x7F5c764cBc14f9669B88837ca1490cCa17c31607).balanceOf(address(this)), 15000e6);
    // }

    function testAvaxUniswapV2LogicSingleToSingle() public {
        uint8[] memory steps = new uint8[](3);
        steps[0] = 2;
        steps[1] = 6;
        steps[2] = 10;
        bytes[] memory data = new bytes[](3);
        address[] memory path = new address[](2);
        path[0] = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
        path[1] = address(0x62edc0692BD897D2295872a9FFCac5425011c661);
        CrossChainSwaps.UniswapV2Params[] memory traderJoe = new CrossChainSwaps.UniswapV2Params[](1);
        traderJoe[0] = CrossChainSwaps.UniswapV2Params(10 ether, 0, path, block.timestamp);
        CrossChainSwaps.SrcTransferParams[] memory srcTransfer = new CrossChainSwaps.SrcTransferParams[](1);
        srcTransfer[0] = CrossChainSwaps.SrcTransferParams(address(0x62edc0692BD897D2295872a9FFCac5425011c661), address(this), 0);
        data[0] = abi.encode(10 ether);
        data[1] = abi.encode(traderJoe);
        data[2] = abi.encode(srcTransfer);
        avax.swaps{value: 10 ether}(steps, data);
        assertGt(IERC20(address(0x62edc0692BD897D2295872a9FFCac5425011c661)).balanceOf(address(this)), 45e17);
        //.0023759693474229510
        //4.749562725498477745
    }

    function testAvaxUniswapV2LogicSingleToMulti() public {
        uint8[] memory steps = new uint8[](3);
        steps[0] = 2;
        steps[1] = 6;
        steps[2] = 10;
        bytes[] memory data = new bytes[](3);
        address[] memory path = new address[](2);
        path[0] = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
        path[1] = address(0x62edc0692BD897D2295872a9FFCac5425011c661);
        address[] memory path2 = new address[](2);
        path2[0] = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
        path2[1] = address(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);
        CrossChainSwaps.UniswapV2Params[] memory traderJoe = new CrossChainSwaps.UniswapV2Params[](2);
        traderJoe[0] = CrossChainSwaps.UniswapV2Params(5 ether, 0, path, block.timestamp);
        traderJoe[1] = CrossChainSwaps.UniswapV2Params(5 ether, 0, path2, block.timestamp);
        CrossChainSwaps.SrcTransferParams[] memory srcTransfer = new CrossChainSwaps.SrcTransferParams[](2);
        srcTransfer[0] = CrossChainSwaps.SrcTransferParams(address(0x62edc0692BD897D2295872a9FFCac5425011c661), address(this), 0);
        srcTransfer[1] = CrossChainSwaps.SrcTransferParams(address(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E), address(this), 0);
        data[0] = abi.encode(10 ether);
        data[1] = abi.encode(traderJoe);
        data[2] = abi.encode(srcTransfer);
        avax.swaps{value: 10 ether}(steps, data);
        assertGt(IERC20(address(0x62edc0692BD897D2295872a9FFCac5425011c661)).balanceOf(address(this)), 2e18);
        assertGt(IERC20(address(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E)).balanceOf(address(this)), 90e6);
    }
}
