// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CrossChainSwaps/CrossChainSwaps.sol";
import "../src/mocks/MockERC20.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/CrossChainSwaps/adapters/StargateAdapter.sol";

contract CrossChainSwapsTest is Test {
    CrossChainSwaps swap;
    CrossChainSwaps avaxSwap;
    CrossChainSwaps bnbSwap;
    MockERC20 mock;

    function setUp() public {
        swap = new CrossChainSwaps(
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2),
            ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564),
            address(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac),
            bytes32(
                0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303
            ),
            IStargateRouter(0x8731d54E9D02c286767d56ac03e8037C07e01e98)
        );
        avaxSwap = new CrossChainSwaps(
            address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7),
            ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564),
            address(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac),
            bytes32(
                0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303
            ),
            IStargateRouter(address(this))
        );
        bnbSwap = new CrossChainSwaps(
            address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c),
            ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564),
            address(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac),
            bytes32(
                0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303
            ),
            IStargateRouter(address(this))
        );
        mock = new MockERC20("Mock", "MRC", address(this), 1e40);
        mock.approveInternal(address(this), address(swap), type(uint256).max);
    }

    function testWethDeposit() public {
        uint8[] memory step = new uint8[](1);
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodePacked(uint256(10 ether));
        step[0] = 2;
        uint256 amount = 10 ether;
        swap.swaps{value: amount}(step, data);
        assertGt(IERC20(swap.weth()).balanceOf(address(swap)), 0);
        assertEq(IERC20(swap.weth()).balanceOf(address(swap)), amount);
    }

    function testUniswap() public {
        uint8[] memory step = new uint8[](2);
        step[0] = 2;
        step[1] = 3;
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodePacked(uint256(10 ether));
        data[1] = abi.encode(
            uint256(10 ether),
            address(swap.weth()),
            address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48),
            uint24(3000)
        );

        uint256 amount = 10 ether;
        swap.swaps{value: amount}(step, data);
        assertGt(
            IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).balanceOf(
                address(swap)
            ),
            0
        );
    }

    function testUniswapMultiSwap() public {
        uint8[] memory step = new uint8[](2);
        step[0] = 2;
        step[1] = 4;
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodePacked(uint256(10 ether));
        data[1] = abi.encode(
            uint256(10 ether),
            address(swap.weth()),
            address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48),
            address(0x6B175474E89094C44Da98b954EedeAC495271d0F),
            uint24(3000),
            uint24(500)
        );

        uint256 amount = 10 ether;
        swap.swaps{value: amount}(step, data);
        assertGt(
            IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F).balanceOf(
                address(swap)
            ),
            0
        );
    }

    function testSushiLegacy() public {
        uint8[] memory step = new uint8[](2);
        step[0] = 2;
        step[1] = 5;
        address[] memory path = new address[](2);
        path[0] = address(swap.weth());
        path[1] = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodePacked(uint256(10 ether));
        data[1] = abi.encode(
            uint256(10 ether),
            uint256(10000 * 1e18),
            path,
            address(swap),
            true
        );

        uint256 amount = 10 ether;
        swap.swaps{value: amount}(step, data);
        assertGt(
            IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F).balanceOf(
                address(swap)
            ),
            0
        );
    }

    function testJoe() public {
        uint8[] memory step = new uint8[](2);
        step[0] = 2;
        step[1] = 6;
        address[] memory path = new address[](2);
        path[0] = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
        path[1] = address(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodePacked(uint256(10 ether));
        data[1] = abi.encode(
            uint256(10 ether),
            uint256(0),
            path,
            address(avaxSwap),
            block.timestamp
        );

        uint256 amount = 10 ether;
        avaxSwap.swaps{value: amount}(step, data);
        assertGt(IERC20(path[1]).balanceOf(address(avaxSwap)), 100 * 1e6);
    }

    function testPancake() public {
        uint8[] memory step = new uint8[](2);
        step[0] = 2;
        step[1] = 7;
        address[] memory path = new address[](2);
        path[0] = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
        path[1] = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodePacked(uint256(10 ether));
        data[1] = abi.encode(
            uint256(10 ether),
            uint256(2500 * 1e18),
            path,
            address(bnbSwap),
            block.timestamp
        );

        uint256 amount = 11 ether;
        bnbSwap.swaps{value: amount}(step, data);
        assertGt(IERC20(path[1]).balanceOf(address(bnbSwap)), 2500 * 1e18);
    }

    function testStargateSwap() public {
        //need to also get the data and steps to send with this step. Has to perform a swap
        // uint16 dstChainId; // stargate dst chain id
        // address token; // token getting bridged
        // uint256 srcPoolId; // stargate src pool id
        // uint256 dstPoolId; // stargate dst pool id
        // uint256 amount; // amount to bridge
        // uint256 amountMin; // amount to bridge minimum
        // uint256 dustAmount; // native token to be received on dst chain
        // address receiver; // Mugen contract on dst chain
        // address to; // receiver bridge token incase of transaction reverts on dst chain
        // uint256 gas; // extra gas to be sent for dst chain operations
        // bytes32 srcContext; // random bytes32 as source context
        StargateAdapter.StargateParams memory params = StargateAdapter
            .StargateParams(
                106,
                0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
                1,
                1,
                1,
                0,
                1e18,
                0xd6eE20BEe516920c606c60B8F9C823Cd5902634f,
                0x6Cb6D9Fb673CfbF31b3A432F6316fE3196efd4aA,
                1e18,
                bytes32("0xsadg")
            );

        bytes memory data;
        uint8[] memory step;
        uint8[] memory steps = new uint8[](3);
        steps[0] = 2;
        steps[1] = 3;
        steps[2] = 9;
        bytes[] memory datas = new bytes[](3);
        datas[0] = abi.encode(uint256(1 ether));
        datas[1] = abi.encode(
            uint256(1e18),
            address(swap.weth()),
            address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48),
            uint24(3000),
            address(swap)
        );
        datas[2] = abi.encode(params, step, data);

        uint256 amount = 100e18;
        address(swap).call{value: 1e18}("");
        swap.swaps{value: amount}(steps, datas);
        // Fails due to layer Zero Fee
    }

    function testComplexPath() public {
        bytes memory data;
        uint8[] memory step;
        uint8[] memory steps = new uint8[](2);
        steps[0] = 2;
        steps[1] = 3;
        //steps[2] = 3;
        bytes[] memory datas = new bytes[](2);
        datas[0] = abi.encode(uint256(10 ether));
        datas[1] = abi.encode(
            uint256(5e18),
            address(swap.weth()),
            address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48),
            uint24(3000),
            address(this)
        );
        // datas[2] = abi.encode(
        //     uint256(5e18),
        //     address(swap.weth()),
        //     address(0x6B175474E89094C44Da98b954EedeAC495271d0F),
        //     uint24(3000),
        //     address(this)
        // );

        uint256 amount = 10e18;
        address(swap).call{value: 10e18}("");
        swap.swaps{value: amount}(steps, datas);
        //Rough Estimate of what the USDC return should be
        assertGt(
            IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).balanceOf(
                address(this)
            ),
            6000e6
        );
        //Rough Estimate of what the DAI return should be
        // assertGt(
        //     IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F).balanceOf(
        //         address(this)
        //     ),
        //     6000e18
        // );
        //254312 Gas
    }
}
