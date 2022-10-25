// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import {ISwapRouter} from "uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {TransferHelper} from "uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";

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

        // Approve the router to spend token1.
        TransferHelper.safeApprove(
            token1,
            address(swapRouter),
            IERC20(token1).balanceOf(address(this))
        );

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: token1,
                tokenOut: token2,
                fee: poolFee,
                recipient: _recipient,
                deadline: block.timestamp,
                amountIn: IERC20(token1).balanceOf(address(this)),
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }

    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its token1 for this function to succeed.
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
        // Approve the router to spend token1.
        TransferHelper.safeApprove(
            token1,
            address(swapRouter),
            IERC20(token1).balanceOf(address(this))
        );

        // Multiple pool swaps are encoded through bytes called a `path`. A path is a sequence of token addresses and poolFees that define the pools used in the swaps.
        // The format for pool encoding is (tokenIn, fee, tokenOut/tokenIn, fee, tokenOut) where tokenIn/tokenOut parameter is the shared token across the pools.
        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: abi.encodePacked(token1, fee1, token2, fee2, token3),
                recipient: to,
                deadline: block.timestamp,
                amountIn: IERC20(token1).balanceOf(address(this)),
                amountOutMinimum: amountOutMin
            });

        // Executes the swap.
        amountOut = swapRouter.exactInput(params);
    }
}
