// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import {ISwapRouter} from "uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {TransferHelper} from "uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

abstract contract UniswapAdapter {
    ISwapRouter public immutable swapRouter;

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }

    function swapExactInputSingle(
        uint256 amountIn,
        address token1,
        address token2,
        uint24 poolFee,
        address _recipient
    ) internal returns (uint256 amountOut) {
        // msg.sender must approve this contract

        // Approve the router to spend DAI.
        TransferHelper.safeApprove(token1, address(swapRouter), amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: token1,
                tokenOut: token2,
                fee: poolFee,
                recipient: _recipient,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }

    /// @notice swapInputMultiplePools swaps a fixed amount of DAI for a maximum possible amount of WETH9 through an intermediary pool.
    /// For this example, we will swap DAI to USDC, then USDC to WETH9 to achieve our desired output.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its DAI for this function to succeed.
    /// @param amountIn The amount of token1 to be swapped.
    /// @return amountOut The amount of token3 received after the swap.
    function swapExactInputMultihop(
        uint256 amountIn,
        uint256 amountOutMin,
        address token1,
        address token2,
        address token3,
        uint24 fee1,
        uint24 fee2,
        address to
    ) internal returns (uint256 amountOut) {
        // Approve the router to spend DAI.
        TransferHelper.safeApprove(token1, address(swapRouter), amountIn);

        // Multiple pool swaps are encoded through bytes called a `path`. A path is a sequence of token addresses and poolFees that define the pools used in the swaps.
        // The format for pool encoding is (tokenIn, fee, tokenOut/tokenIn, fee, tokenOut) where tokenIn/tokenOut parameter is the shared token across the pools.
        // Since we are swapping DAI to USDC and then USDC to WETH9 the path encoding is (DAI, 0.3%, USDC, 0.3%, WETH9).
        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: abi.encodePacked(token1, fee1, token2, fee2, token3),
                recipient: to,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin
            });

        // Executes the swap.
        amountOut = swapRouter.exactInput(params);
    }
}
