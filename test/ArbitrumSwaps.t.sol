//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/CrossChainSwaps/Chains/Arbitrum/ArbitrumSwaps.sol";
import "../src/CrossChainSwaps/FeeCollector.sol";

contract ArbitrumSwapsTest is Test {
    ArbitrumSwaps arbitrumSwaps;
    FeeCollector feeCollector;
    address USDCWhale = address(0x62ED28802362bB79eF4cEe858d4F7aCA5eDd0490); // 1.6 million USDC
    address GMXWhale = address(0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a); //25k GMX
    address usdc = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address gmx = address(0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a);
    address weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address dai = address(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
    address xcal = address(0xd2568acCD10A4C98e87c44E9920360031ad89fCB);

    function setUp() public {
        feeCollector = new FeeCollector();
        arbitrumSwaps = new ArbitrumSwaps(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1, 
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564), 
        address(feeCollector), 
        0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac, 
        0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303, 
        0xD158bd9E8b6efd3ca76830B66715Aa2b7Bad2218,
        IStargateRouter(0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614));
        vm.prank(USDCWhale);
        IERC20(usdc).transfer(address(this), 1e7);
        vm.prank(GMXWhale);
        IERC20(gmx).transfer(address(this), 5e18);
    }

    function testEthDeposit() public {
        uint8[] memory steps = new uint8[](1);
        bytes[] memory data = new bytes[](1);
        steps[0] = 2;
        data[0] = abi.encode(10 ether);
        arbitrumSwaps.arbitrumSwaps{value: 10 ether}(steps, data);
        assertEq(IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1).balanceOf(address(arbitrumSwaps)), 10 ether);
    }

    function testERC20Deposits() public {
        IERC20(gmx).approve(address(arbitrumSwaps), type(uint256).max);
        IERC20(usdc).approve(address(arbitrumSwaps), type(uint256).max);

        address[] memory tokens = new address[](2);
        tokens[0] = usdc;
        tokens[1] = gmx;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e7;
        amounts[1] = 5e18;
        
        uint8[] memory steps = new uint8[](1);
        steps[0] = 1;
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encode(tokens, amounts);

        arbitrumSwaps.arbitrumSwaps(steps, data);
        assertEq(IERC20(usdc).balanceOf(address(arbitrumSwaps)), 1e7);
        assertEq(IERC20(gmx).balanceOf(address(arbitrumSwaps)), 5e18);
    }

    //Gas: 322729
    function testArbitrumUniSingle() public {
        tokenApprovals();
        address[] memory tokens = new address[](2);
        tokens[0] = usdc;
        tokens[1] = gmx;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e7;
        amounts[1] = 5e18;

        UniswapAdapter.UniswapV3Single[] memory params = new UniswapAdapter.UniswapV3Single[](2);
        params[0] = UniswapAdapter.UniswapV3Single(1e7, 0, usdc, weth, 500);
        params[1] = UniswapAdapter.UniswapV3Single(5e18, 0, gmx, weth, 3000);
        
        uint8[] memory steps = new uint8[](2);
        steps[0] = 1;
        steps[1] = 3;
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encode(tokens, amounts);
        data[1] = abi.encode(params);

        arbitrumSwaps.arbitrumSwaps(steps, data);
        assertGt(IERC20(weth).balanceOf(address(arbitrumSwaps)), 0);
    }

    //Gas: 448953
    function testArbitrumUniMulti() public {
        tokenApprovals();
        address[] memory tokens = new address[](2);
        tokens[0] = usdc;
        tokens[1] = gmx;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e7;
        amounts[1] = 5e18;

        UniswapAdapter.UniswapV3Multi[] memory params = new UniswapAdapter.UniswapV3Multi[](2);
        params[0] = UniswapAdapter.UniswapV3Multi(1e7, 0, usdc, weth, dai, 500, 500);
        params[1] = UniswapAdapter.UniswapV3Multi(5e18, 0, gmx, weth, dai, 3000, 500);
        
        uint8[] memory steps = new uint8[](2);
        steps[0] = 1;
        steps[1] = 4;
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encode(tokens, amounts);
        data[1] = abi.encode(params);

        arbitrumSwaps.arbitrumSwaps(steps, data);
        assertGt(IERC20(dai).balanceOf(address(arbitrumSwaps)), 0);
    }

    function testArbitrumSushi() public {}

    function testArbitrumXcal() public {
        uint8[] memory steps = new uint8[](2);
        steps[0] = 2;
        steps[1] = 6;

        XCaliburAdapter.XcaliburParams[] memory params = new XCaliburAdapter.XcaliburParams[](1);
        XCaliburAdapter.route[] memory routes = new XCaliburAdapter.route[](2);
        routes[0] = XCaliburAdapter.route(weth, usdc, false);
        routes[1] = XCaliburAdapter.route(usdc, xcal, false);
        params[0] = XCaliburAdapter.XcaliburParams(10 ether, 0, routes, block.timestamp);

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encode(11 ether);
        data[1] = abi.encode(params);

        arbitrumSwaps.arbitrumSwaps{value: 11 ether}(steps, data);
        //assertGt(IERC20(weth).balanceOf(address(arbitrumSwaps)), 0);
        assertGt(IERC20(xcal).balanceOf(address(arbitrumSwaps)),0);
        emit log_uint(IERC20(xcal).balanceOf(address(arbitrumSwaps)));
    }

    function testArbitrumSRCTransfer() public {}

    function testArbitrumWethWithdraw() public {}

    function testArbitrumStargate() public {}

    function tokenApprovals() internal {
        IERC20(gmx).approve(address(arbitrumSwaps), type(uint256).max);
        IERC20(usdc).approve(address(arbitrumSwaps), type(uint256).max);
    }

    receive() external payable {}
}