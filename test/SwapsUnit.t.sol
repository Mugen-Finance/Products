// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CrossChainSwaps/CrossChainSwaps.sol";
import "../src/mocks/MockERC20.sol";
import "../src/CrossChainSwaps/adapters/StargateAdapter.sol";
import "../src/CrossChainSwaps/adapters/VelodromeAdapter.sol";
import "../src/CrossChainSwaps/adapters/UniswapAdapter.sol";

//Fork Tests

contract SwapsUnitTest is Test {
    CrossChainSwaps swaps;
    MockERC20 token1;
    MockERC20 token2;
    MockERC20 token3;
    address alice = address(0x124);

    function setUp() public {
        swaps = new CrossChainSwaps( //Optimism Setup
            address(0x4200000000000000000000000000000000000006),
            ISwapRouter(address(0xE592427A0AEce92De3Edee1F18E0157C05861564)),
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000000000000000000000000000,
            0x25CbdDb98b35ab1FF77413456B31EC81A6B6B746,
            address(0x4200000000000000000000000000000000000006),
            IStargateRouter(address(0xB0D502E938ed5f4df2E681fE6E419ff29631d62b))
        );
        token1 = new MockERC20(
            "Token 1",
            "TK1",
            address(this),
            type(uint256).max
        );
        token2 = new MockERC20(
            "Token 2",
            "TK2",
            address(this),
            type(uint256).max
        );
        token3 = new MockERC20(
            "Token 3",
            "TK3",
            address(this),
            type(uint256).max
        );
    }

    function testOptimismExchangeVelo() public {
        uint256 time = block.timestamp + 20 days;
        uint8[] memory steps = new uint8[](3);
        steps[0] = 2;
        steps[1] = 9;
        steps[2] = 10;
        //-------------------------------------------------------------------
        //-------------------------------------------------------------------
        VelodromeAdapter.route[] memory routes = new VelodromeAdapter.route[](
            1
        );
        routes[0] = VelodromeAdapter.route(
            0x4200000000000000000000000000000000000006,
            0x7F5c764cBc14f9669B88837ca1490cCa17c31607,
            false
        );
        VelodromeAdapter.VeloParams[]
            memory velo = new VelodromeAdapter.VeloParams[](1);
        velo[0] = VelodromeAdapter.VeloParams(10 ether, 0, routes, time);
        //-------------------------------------------------------------------
        //-------------------------------------------------------------------
        CrossChainSwaps.SrcTransferParams[]
            memory srcTransfer = new CrossChainSwaps.SrcTransferParams[](1);

        srcTransfer[0] = CrossChainSwaps.SrcTransferParams(
            address(0x7F5c764cBc14f9669B88837ca1490cCa17c31607),
            address(this),
            0
        );
        //-------------------------------------------------------------------
        //-------------------------------------------------------------------
        bytes[] memory data = new bytes[](3);
        data[0] = abi.encode(10 ether);
        data[1] = abi.encode(velo);
        data[2] = abi.encode(srcTransfer);
        //-------------------------------------------------------------------
        //-------------------------------------------------------------------
        swaps.swaps{value: 10 ether}(steps, data);
        assertGt(
            IERC20(0x7F5c764cBc14f9669B88837ca1490cCa17c31607).balanceOf(
                address(this)
            ),
            15000e6
        );
    }

    function testOptimismExchangeUniSingle() public {}

    function testOptimismExchangeUniMulti() public {}
}
