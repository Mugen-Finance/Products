// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CrossChainSwaps/CrossChainSwaps.sol";
import "../src/mocks/MockERC20.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/CrossChainSwaps/adapters/StargateAdapter.sol";

//Check fee calc again

contract SwapsUnitTest is Test {
    CrossChainSwaps swaps;
    MockERC20 token1;
    MockERC20 token2;
    MockERC20 token3;
    address alice = address(0x124);

    function setUp() public {
        swaps = new CrossChainSwaps(
            address(0x4200000000000000000000000000000000000006),
            ISwapRouter(address(0)),
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000000000000000000000000000,
            0x25CbdDb98b35ab1FF77413456B31EC81A6B6B746,
            address(0x4200000000000000000000000000000000000006),
            IStargateRouter(address(0))
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

    //Gas: 35661
    function testSingleDeposits(uint256 x, address _addr) public {
        vm.assume(x > 1);
        vm.assume(x < type(uint216).max);
        vm.assume(_addr != address(0));
        vm.assume(_addr != address(this));
        IERC20(token1).transfer(_addr, type(uint256).max);
        vm.startPrank(_addr);
        IERC20(token1).approve(address(swaps), type(uint256).max);
        uint8[] memory steps = new uint8[](2);
        bytes[] memory data = new bytes[](2);
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        tokens[0] = address(token1);
        amounts[0] = x;
        steps[0] = 1;
        steps[1] = 11;
        data[0] = abi.encode(address(token1), x);
        CrossChainSwaps.SrcTransferParams memory params = CrossChainSwaps
            .SrcTransferParams(tokens, address(_addr), amounts);
        data[1] = abi.encode(params);
        uint256 fee = x - ((x * 9995) / 1e4); // calculate fee for missing value

        swaps.swaps(steps, data);

        assertEq(
            IERC20(token1).balanceOf(address(_addr)),
            (type(uint256).max - fee)
        );
        assertEq(IERC20(token1).balanceOf(address(swaps)), 0);
        vm.stopPrank();
    }

    //Gas:  100857
    function testBatchDeposits(uint256 x, address _addr) public {
        vm.assume(x > 1);
        vm.assume(x < type(uint216).max);
        vm.assume(_addr != address(0));
        vm.assume(_addr != address(this));
        IERC20(token1).transfer(_addr, type(uint256).max);
        IERC20(token2).transfer(_addr, type(uint256).max);
        IERC20(token3).transfer(_addr, type(uint256).max);
        vm.startPrank(_addr);
        IERC20(token1).approve(address(swaps), type(uint256).max);
        IERC20(token2).approve(address(swaps), type(uint256).max);
        IERC20(token3).approve(address(swaps), type(uint256).max);
        uint8[] memory steps = new uint8[](2);
        bytes[] memory data = new bytes[](2);
        address[] memory tokens = new address[](3);
        uint256[] memory amounts = new uint256[](3);
        tokens[0] = address(token1);
        tokens[1] = address(token2);
        tokens[2] = address(token3);
        amounts[0] = x;
        amounts[1] = x;
        amounts[2] = x;
        steps[0] = 2;
        steps[1] = 11;
        data[0] = abi.encode(tokens, amounts);
        CrossChainSwaps.SrcTransferParams memory params = CrossChainSwaps
            .SrcTransferParams(tokens, address(_addr), amounts);
        data[1] = abi.encode(params);
        uint256 fee = x - ((x * 9995) / 1e4); // calculate fee for missing value

        swaps.swaps(steps, data);

        assertEq(
            IERC20(token1).balanceOf(address(_addr)),
            (type(uint256).max - fee)
        );
        assertEq(
            IERC20(token2).balanceOf(address(_addr)),
            (type(uint256).max - fee)
        );
        assertEq(
            IERC20(token3).balanceOf(address(_addr)),
            (type(uint256).max - fee)
        );
        assertEq(IERC20(token1).balanceOf(address(swaps)), 0);
        assertEq(IERC20(token2).balanceOf(address(swaps)), 0);
        assertEq(IERC20(token3).balanceOf(address(swaps)), 0);
        vm.stopPrank();
    }
}
