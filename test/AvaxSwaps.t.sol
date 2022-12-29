//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/CrossChainSwaps/Chains/Avax/AvaxSwaps.sol";
import "../src/CrossChainSwaps/FeeCollector.sol";

contract AvaxSwapsTest is Test {
    AvaxSwaps avaxSwaps;
    FeeCollector collector;

    function setUp() public {
        collector = new FeeCollector();
        avaxSwaps =
        new AvaxSwaps(IWETH9(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7), 
        address(0x60aE616a2155Ee3d9A68541Ba4544862310933d4), 
        address(0xE3Ffc583dC176575eEA7FD9dF2A7c65F7E23f4C3), 
        address(collector), 
        address(0xc35DADB65012eC5796536bD9864eD8773aBc74C4), 
        bytes32(0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303), 
        IStargateRouter(0x45A01E4e04F14f7A4a6702c74187c5F6222033cd));
        //These are testnet so just fix this before testing
    }

    function testLB() public {
        uint8[] memory steps = new uint8[](3);
        bytes[] memory data = new bytes[](3);

        steps[0] = 2;
        steps[1] = 11;
        steps[2] = 13;

        address[] memory path = new address[](2);
        path[0] = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
        path[1] = address(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);

        uint256[] memory binSteps = new uint256[](1);
        binSteps[0] = 20;

        AvaxSwaps.LiquidityBookParams[] memory params = new AvaxSwaps.LiquidityBookParams[](1);
        params[0] = AvaxSwaps.LiquidityBookParams({
            amountIn: 10 ether,
            amountOutWithSlippage: 10e7,
            pairBinSteps: binSteps,
            tokenPath: path
        });

        AvaxSwaps.SrcTransferParams[] memory srcTransferData = new AvaxSwaps.SrcTransferParams[](1);
        srcTransferData[0] = AvaxSwaps.SrcTransferParams({
            token: address(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E),
            receiver: address(this),
            amount: IERC20(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E).balanceOf(address(avaxSwaps))
        });

        data[0] = abi.encode(10 ether);
        data[1] = abi.encode(params);
        data[2] = abi.encode(srcTransferData);

        avaxSwaps.avaxSwaps{value: 10 ether}(steps, data);
    }
}
