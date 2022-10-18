//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * Walkthrough code, look for optimizations, testing
 * Do I need to ass Dst transferTo, add exact output from uniswap (would this even work properly?)
 */

import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWETH9} from "./interfaces/IWETH9.sol";
import {IJoeRouter02} from "traderjoe/contracts/traderjoe/interfaces/IJoeRouter02.sol";
import {IPancakeRouter02} from "pancake/projects/exchange-protocol/contracts/interfaces/IPancakeRouter02.sol";
import {IUniswapV2Router02} from "spookyswap/contracts/interfaces/IUniswapV2Router02.sol";
import "./adapters/UniswapAdapter.sol";
import "./adapters/SushiAdapter.sol";
import "./adapters/StargateAdapter.sol";

contract CrossChainSwaps is
    UniswapAdapter,
    SushiLegacyAdapter,
    StargateAdapter
{
    using SafeERC20 for IERC20;

    error MustBeGt0();

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    IJoeRouter02 public constant joeRouter =
        IJoeRouter02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    IPancakeRouter02 public constant pancakeRouter =
        IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IUniswapV2Router02 public constant spookyRouter =
        IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
    uint8 internal constant DEPOSIT = 1;
    uint8 internal constant WETH_DEPOSIT = 2;
    uint8 internal constant UNISWAP_INPUT_SINGLE = 3;
    uint8 internal constant UNISWAP_INPUT_MULTI = 4;
    uint8 internal constant SUSHI_LEGACY = 5;
    uint8 internal constant TRADERJOE_SWAP = 6;
    uint8 internal constant PANCAKE_SWAP = 7;
    uint8 internal constant SPOOKY_SWAP = 8;
    uint8 internal constant STARGATE = 9;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    address public immutable weth;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _weth,
        ISwapRouter _swapRouter,
        address _factory,
        bytes32 _pairCodeHash,
        IStargateRouter _stargateRouter
    )
        UniswapAdapter(_swapRouter)
        SushiLegacyAdapter(_factory, _pairCodeHash)
        StargateAdapter(_stargateRouter)
    {
        weth = _weth;
    }

    /*//////////////////////////////////////////////////////////////
                               USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    ///@param steps one way array mapping steps with actions
    ///@param data one way array of data to perform at each called step
    function swaps(uint8[] memory steps, bytes[] memory data) external payable {
        if (msg.value <= 0) revert MustBeGt0();
        for (uint256 i; i < steps.length; i++) {
            uint8 step = steps[i];
            if (step == DEPOSIT) {
                (address _token, uint256 _amount) = abi.decode(
                    data[i],
                    (address, uint256)
                );
                IERC20(_token).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _amount
                );
            } else if (step == WETH_DEPOSIT) {
                uint256 _amount = abi.decode(data[i], (uint256));
                IWETH9(weth).deposit{value: _amount}();
            } else if (step == UNISWAP_INPUT_SINGLE) {
                (
                    uint256 amountIn,
                    address token1,
                    address token2,
                    uint24 poolFee
                ) = abi.decode(data[i], (uint256, address, address, uint24));
                swapExactInputSingle(amountIn, token1, token2, poolFee);
            } else if (step == UNISWAP_INPUT_MULTI) {
                (
                    uint256 amountIn,
                    address token1,
                    address token2,
                    address token3,
                    uint24 fee1,
                    uint24 fee2
                ) = abi.decode(
                        data[i],
                        (uint256, address, address, address, uint24, uint24)
                    );
                swapExactInputMultihop(
                    amountIn,
                    token1,
                    token2,
                    token3,
                    fee1,
                    fee2
                );
            } else if (step == SUSHI_LEGACY) {
                (
                    uint256 amountIn,
                    uint256 amountOutMin,
                    address[] memory path,
                    address to,
                    bool sendTokens
                ) = abi.decode(
                        data[i],
                        (uint256, uint256, address[], address, bool)
                    );
                _swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    path,
                    to,
                    sendTokens
                );
            } else if (step == TRADERJOE_SWAP) {
                (
                    uint256 amountIn,
                    uint256 amountOutMin,
                    address[] memory path,
                    address to,
                    uint256 deadline
                ) = abi.decode(
                        data[i],
                        (uint256, uint256, address[], address, uint256)
                    );
                IERC20(path[0]).safeIncreaseAllowance(
                    address(joeRouter),
                    amountIn
                );
                IJoeRouter02(joeRouter).swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    path,
                    to,
                    deadline
                );
            } else if (step == PANCAKE_SWAP) {
                (
                    uint256 amountIn,
                    uint256 amountOutMin,
                    address[] memory path,
                    address to,
                    uint256 deadline
                ) = abi.decode(
                        data[i],
                        (uint256, uint256, address[], address, uint256)
                    );
                IERC20(path[0]).safeIncreaseAllowance(
                    address(pancakeRouter),
                    amountIn
                );
                pancakeRouter.swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    path,
                    to,
                    deadline
                );
            } else if (step == SPOOKY_SWAP) {
                (
                    uint256 amountIn,
                    uint256 amountOutMin,
                    address[] memory path,
                    address to,
                    uint256 deadline
                ) = abi.decode(
                        data[i],
                        (uint256, uint256, address[], address, uint256)
                    );
                spookyRouter.swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    path,
                    to,
                    deadline
                );
            } else if (step == STARGATE) {
                (
                    StargateParams memory params,
                    uint8[] memory stepperions,
                    bytes[] memory datass
                ) = abi.decode(data[i], (StargateParams, uint8[], bytes[]));
                stargateSwap(params, stepperions, datass);
            }
        }
    }

    receive() external payable {}
}
