//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/CrossChainSwaps/Chains/Optimism/OptimismSwaps.sol";
import "../src/CrossChainSwaps/FeeCollector.sol";
import "../src/CrossChainSwaps/adapters/VelodromeAdapter.sol";

contract OptimismTest is Test {
    OptimismSwaps swaps;
    FeeCollector feeCollector;
    uint256 amount = 0.001 ether;

    function setUp() public {
        feeCollector = new FeeCollector();
        swaps = new OptimismSwaps(
            IWETH9(0x4200000000000000000000000000000000000006),
            address(feeCollector),
            ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564),
            address(0x0000000000000000000000000000000000000000),
            bytes32(0x0000000000000000000000000000000000000000000000000000000000000000),
            IStargateRouter(0xB0D502E938ed5f4df2E681fE6E419ff29631d62b)
        );

        vm.prank(address(0xc66825C5c04b3c2CcD536d626934E16248A63f68));
        IERC20(0x7F5c764cBc14f9669B88837ca1490cCa17c31607).transfer(address(this), 10e10);
    }

    function testVelo() public {
        IERC20(0x7F5c764cBc14f9669B88837ca1490cCa17c31607).approve(address(swaps), 10e10);
        uint8[] memory steps = new uint8[](3);
        steps[0] = 1;
        steps[1] = 10;
        steps[2] = 14;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10e10;

        address[] memory tokens = new address[](1);
        tokens[0] = address(0x7F5c764cBc14f9669B88837ca1490cCa17c31607);

        bytes[] memory data = new bytes[](3);
        data[0] = abi.encode(tokens, amounts);

        VelodromeAdapter.route[] memory routes = new VelodromeAdapter.route[](1);
        routes[0] = VelodromeAdapter.route(
            address(0x7F5c764cBc14f9669B88837ca1490cCa17c31607),
            address(0x4200000000000000000000000000000000000006),
            false
        );
        OptimismSwaps.SrcTransferParams[] memory srcParams = new  OptimismSwaps.SrcTransferParams[](1);
        srcParams[0] = OptimismSwaps.SrcTransferParams({
            token: address(0x4200000000000000000000000000000000000006),
            receiver: address(0xD471AeC6c713379f0b928FA8cb80b9761Cd9708d),
            amount: IERC20(address(0x4200000000000000000000000000000000000006)).balanceOf(address(swaps))
        });
        VelodromeAdapter.VeloParams[] memory veloParams = new VelodromeAdapter.VeloParams[](1);
        veloParams[0] = VelodromeAdapter.VeloParams(10e10, 0, routes, block.timestamp + 10 minutes);
        data[1] = abi.encode(veloParams);
        data[2] = abi.encode(srcParams);

        swaps.optimismSwaps(steps, data);
        assertEq(IERC20(0x4200000000000000000000000000000000000006).balanceOf(address(swaps)), 0 ether);
        assertGt(
            IERC20(0x4200000000000000000000000000000000000006).balanceOf(
                address(0xD471AeC6c713379f0b928FA8cb80b9761Cd9708d)
            ),
            0
        );
    }

    function testOptimismUniMultiHop() public {
        uint8[] memory steps = new uint8[](3);
        bytes[] memory data = new bytes[](3);

        steps[0] = 2;
        steps[1] = 4;
        steps[2] = 14;

        OptimismSwaps.UniswapV3Multi[] memory multiHopParams = new OptimismSwaps.UniswapV3Multi[](1);
        multiHopParams[0] = UniswapAdapter.UniswapV3Multi({
            amountIn: 10 ether,
            amountOutMin: 0,
            token1: address(0x4200000000000000000000000000000000000006),
            token2: address(0x7F5c764cBc14f9669B88837ca1490cCa17c31607),
            token3: address(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1),
            fee1: 500,
            fee2: 500
        });

        OptimismSwaps.SrcTransferParams[] memory transferParams = new OptimismSwaps.SrcTransferParams[](1);

        transferParams[0] = OptimismSwaps.SrcTransferParams({
            token: 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1,
            receiver: address(this),
            amount: 0
        });

        data[0] = abi.encode(10 ether);
        data[1] = abi.encode(multiHopParams);
        data[2] = abi.encode(transferParams);

        swaps.optimismSwaps{value: 10 ether}(steps, data);
    }
}
