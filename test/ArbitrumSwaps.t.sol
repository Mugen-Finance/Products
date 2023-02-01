//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/CrossChainSwaps/Chains/Arbitrum/ArbitrumSwaps.sol";
import "../src/CrossChainSwaps/adapters/SushiAdapter.sol";
import "../src/CrossChainSwaps/FeeCollector.sol";

//Tests need to be updated for the change is step order and for the adjustment to the camelot adapter.

contract ArbitrumSwapsTest is Test {
    using SafeERC20 for IERC20;
    ArbitrumSwaps arbitrumSwaps;
    FeeCollector feeCollector;
    address USDCWhale = address(0x7B7B957c284C2C227C980d6E2F804311947b84d0); // 1.6 million USDC
    address GMXWhale = address(0xa66f8Db3B8F1e4c79e52ac89Fec052811F4dbd19); //25k GMX
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
        0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 
        0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303, 
        0xD158bd9E8b6efd3ca76830B66715Aa2b7Bad2218,
        0xc873fEcbd354f5A56E00E710B90EF4201db2448d,
        IStargateRouter(0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614));
        vm.prank(USDCWhale);
        IERC20(usdc).transfer(address(this), 10000e7);
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

    function testArbitrumSushi() public {
        uint8[] memory steps = new uint8[](3);
        bytes[] memory data = new bytes[](3);

        steps[0] = 2;
        steps[1] = 5;
        steps[2] = 14;

        address[] memory route = new address[](2);
        route[0] = address(weth);
        route[1] = address(usdc);

        SushiAdapter.SushiParams[] memory params = new ArbitrumSwaps.SushiParams[](1);

        params[0] = SushiAdapter.SushiParams(10 ether, 13e8, route, true);

        ArbitrumSwaps.SrcTransferParams[] memory srcParams = new ArbitrumSwaps.SrcTransferParams[](1);

        srcParams[0] = ArbitrumSwaps.SrcTransferParams({token: address(usdc), receiver: address(this), amount: 0});

        data[0] = abi.encode(10 ether);
        data[1] = abi.encode(params);
        data[2] = abi.encode(srcParams);

        arbitrumSwaps.arbitrumSwaps{value: 10 ether}(steps, data);
        assertGt(IERC20(address(usdc)).balanceOf(address(this)), 13e8);
        assertEq(IERC20(address(usdc)).balanceOf(address(arbitrumSwaps)), 0);
    }

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
        assertGt(IERC20(xcal).balanceOf(address(arbitrumSwaps)), 0);
        emit log_uint(IERC20(xcal).balanceOf(address(arbitrumSwaps)));
    }

    function testArbitrumSRCTransfer() public {
        uint8[] memory steps = new uint8[](2);
        bytes[] memory data = new bytes[](2);
        ArbitrumSwaps.SrcTransferParams[] memory params = new ArbitrumSwaps.SrcTransferParams[](1);

        //params[0] = ArbitrumSwaps.SrcTransferParams({token: address(weth), receiver: address(this), amount: 0});
        params[0] = ArbitrumSwaps.SrcTransferParams({token: address(weth), receiver: address(this), amount: 10 ether});

        steps[0] = 2;
        steps[1] = 14;

        data[0] = abi.encode(10 ether);
        data[1] = abi.encode(params);

        arbitrumSwaps.arbitrumSwaps{value: 10 ether}(steps, data);
        assertEq(IERC20(address(weth)).balanceOf(address(this)), (10 ether * 0.9995));
    }

    function testArbitrumWethWithdraw() public {
        uint8[] memory steps = new uint8[](2);
        bytes[] memory data = new bytes[](2);

        steps[0] = 2;
        steps[1] = 13;

        data[0] = abi.encode(10 ether);
        data[1] = abi.encode(address(this), 0);

        arbitrumSwaps.arbitrumSwaps{value: 10 ether}(steps, data);
        assertEq(IERC20(address(weth)).balanceOf(address(arbitrumSwaps)), 0 ether);
    }

    function testArbitrumStargate() public {
        tokenApprovals();
        uint8[] memory steps = new uint8[](2);
        steps[0] = 1;
        steps[1] = 15;

        bytes[] memory data = new bytes[](2);

        StargateArbitrum.StargateParams memory stargateParams = StargateArbitrum.StargateParams(
            101, address(usdc), 1, 1, 100e7, 0, 1e15, address(this), address(this), 500000, bytes32(0x0)
        );
        /**
         *     uint16 dstChainId; // stargate dst chain id
         *     address token; // token getting bridged
         *     uint256 srcPoolId; // stargate src pool id
         *     uint256 dstPoolId; // stargate dst pool id
         *     uint256 amount; // amount to bridge
         *     uint256 amountMin; // amount to bridge minimum
         *     uint256 dustAmount; // native token to be received on dst chain
         *     address receiver; // Mugen contract on dst chain
         *     address to; // receiver bridge token incase of transaction reverts on dst chain
         *     uint256 gas; // extra gas to be sent for dst chain operations
         *     bytes32 srcContext; //
         */

        uint256[] memory amounts = new uint256[](1);
        address[] memory tokens = new address[](1);
        amounts[0] = 10000e7;
        tokens[0] = address(usdc);
        data[0] = abi.encode(tokens, amounts);
        data[1] = abi.encode(stargateParams, steps, data);

        arbitrumSwaps.arbitrumSwaps{value: 1 ether}(steps, data);
    }

    function testCamelot() public {
        uint8[] memory steps = new uint8[](3);
        bytes[] memory data = new bytes[](3);

        steps[0] = 2;
        steps[1] = 7;
        steps[2] = 14;

        address[] memory path = new address[](2);
        path[0] = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        path[1] = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);

        ArbitrumSwaps.SrcTransferParams[] memory srcParams = new ArbitrumSwaps.SrcTransferParams[](1);

        srcParams[0] = ArbitrumSwaps.SrcTransferParams({token: address(usdc), receiver: address(this), amount: 0});

        data[0] = abi.encode(10 ether);
        data[1] = abi.encode(10 ether, path, address(this), block.timestamp);
        data[2] = abi.encode(srcParams);

        arbitrumSwaps.arbitrumSwaps{value: 10 ether}(steps, data);
        assertGt(IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8).balanceOf(address(this)), 10e10);
        vm.prank(address(arbitrumSwaps));
        uint256 allowance = IERC20(address(weth)).allowance(address(arbitrumSwaps), address(arbitrumSwaps.camelotRouter()));
        console.log("Allowance: %s", allowance);

        arbitrumSwaps.arbitrumSwaps{value: 10 ether}(steps, data);
        vm.prank(address(arbitrumSwaps));
        uint256 newAllowance = IERC20(address(weth)).allowance(address(arbitrumSwaps), address(arbitrumSwaps.camelotRouter()));
        console.log("Allowance: %s", newAllowance);
        assertGt(allowance, newAllowance);
    }

    function testMultiSwaps() public {
        uint256 gmxBeforeBalance = IERC20(address(gmx)).balanceOf(address(this));
        uint256 usdcBeforeBalance = IERC20(address(usdc)).balanceOf(address(this));
        uint8[] memory steps = new uint8[](4);
        bytes[] memory data = new bytes[](4);

        steps[0] = 2;
        steps[1] = 3;
        steps[2] = 4;
        steps[3] = 14;

        ArbitrumSwaps.UniswapV3Single[] memory singleParams = new ArbitrumSwaps.UniswapV3Single[](1);

        singleParams[0] = UniswapAdapter.UniswapV3Single({amountIn: 5 ether,
        amountOutMin: 0,
        token1: address(weth),
        token2: address(gmx),
        poolFee: 3000});

        ArbitrumSwaps.UniswapV3Multi[] memory multiParams = new ArbitrumSwaps.UniswapV3Multi[](1);

        multiParams[0] = UniswapAdapter.UniswapV3Multi({amountIn: 0,
        amountOutMin: 0,
        token1: address(weth),
        token2: address(dai), 
        token3: address(usdc), 
        fee1: 3000,
        fee2: 500});

        ArbitrumSwaps.SrcTransferParams[] memory srcParams = new ArbitrumSwaps.SrcTransferParams[](2);

        srcParams[0] = ArbitrumSwaps.SrcTransferParams({token: address(usdc), receiver: address(this), amount: 0});
        srcParams[1] = ArbitrumSwaps.SrcTransferParams({token: address(gmx), receiver: address(this), amount: 0});

        data[0] = abi.encode(10 ether);
        data[1] = abi.encode(singleParams);
        data[2] = abi.encode(multiParams);
        data[3] = abi.encode(srcParams);

        arbitrumSwaps.arbitrumSwaps{value: 10 ether}(steps, data);
        assertGt(IERC20(address(gmx)).balanceOf(address(this)), gmxBeforeBalance);
        assertGt(IERC20(address(usdc)).balanceOf(address(this)), usdcBeforeBalance);
    }

    function testInvalidStep() public {
        uint8[] memory steps = new uint8[](1);
        bytes[] memory data = new bytes[](1);

        steps[0] = 100;
        data[0] = abi.encode(200 ether);
        vm.expectRevert();
        arbitrumSwaps.arbitrumSwaps(steps, data);
    }

    function testZero() public {
        uint8[] memory steps = new uint8[](1);
        bytes[] memory data = new bytes[](1);

        steps[0] = 2;
        data[0] = abi.encode(0);

        vm.expectRevert();
        arbitrumSwaps.arbitrumSwaps(steps, data);
    }

    function tokenApprovals() internal {
        IERC20(gmx).approve(address(arbitrumSwaps), type(uint256).max);
        IERC20(usdc).approve(address(arbitrumSwaps), type(uint256).max);
    }

    receive() external payable {}
}
