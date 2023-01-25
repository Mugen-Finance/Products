//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/CrossChainSwaps/Chains/Binance/BinanceSwaps.sol";

contract BinanceSwapsTest is Test {
    BinanceSwaps swaps;

    function setUp() public {
        // IWETH9 _weth,
        // address _feeCollector,
        // address _factory,
        // bytes32 _pairCodeHash,
        // IStargateRouter _stargateRouter,
        // IPancakeRouter02 _pancakeRouter
        swaps = new BinanceSwaps(IWETH9(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), address(this), 0xc35DADB65012eC5796536bD9864eD8773aBc74C4 , 0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303,IStargateRouter(0x4a364f8c717cAAD9A442737Eb7b8A55cc6cf18D8), IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E));
    }

    function testPancakeSwap() public {
        uint8[] memory steps = new uint8[](3);
        bytes[] memory data = new bytes[](3);

        steps[0] = 2;
        steps[1] = 8;
        steps[2] = 14;

        BinanceSwaps.UniswapV2Params[] memory params = new  BinanceSwaps.UniswapV2Params[](1);
        address[] memory path = new address[](2);
        path[0] =address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
        path[1] = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        params[0] = BinanceSwaps.UniswapV2Params({amountIn: 10 ether, amountOutMin: 0, path: path, deadline: block.timestamp});

        BinanceSwaps.SrcTransferParams[] memory srcParams = new  BinanceSwaps.SrcTransferParams[](1);
        srcParams[0] =  BinanceSwaps.SrcTransferParams({token: 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56, receiver: address(this), amount: 0});

        data[0] = abi.encode(10 ether);
        data[1] = abi.encode(params);
        data[2] = abi.encode(srcParams);

        swaps.binanceSwaps{value: 10 ether}(steps, data);
        assertEq(IERC20(address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56)).balanceOf(address(swaps)), 0);
    }
}