//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWETH9} from "./interfaces/IWETH9.sol";
import {IJoeRouter02} from "traderjoe/contracts/traderjoe/interfaces/IJoeRouter02.sol";
import {IPancakeRouter02} from "pancake/projects/exchange-protocol/contracts/interfaces/IPancakeRouter02.sol";
import {IUniswapV2Router02} from "spookyswap/contracts/interfaces/IUniswapV2Router02.sol";
import {VelodromeAdapter} from "./adapters/VelodromeAdapter.sol";
import "./adapters/UniswapAdapter.sol";
import "./adapters/SushiAdapter.sol";
import "./adapters/StargateAdapter.sol";

/**@notice allows for cross-chain swaps across multiple chains and exchanges.
 *Also interfaces for exchanges to facilitate swaps that do not involve cross-chain messaging.
 */

contract CrossChainSwaps is
    UniswapAdapter,
    SushiLegacyAdapter,
    StargateAdapter,
    VelodromeAdapter
{
    using SafeERC20 for IERC20;

    error NotEnoughSteps();
    error MoreThanZero();

    struct SrcTransferParams {
        address[] tokens;
        address to;
        uint256[] amounts;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    //Change these for testnet

    IJoeRouter02 public constant joeRouter = IJoeRouter02(address(0));
    IPancakeRouter02 public constant pancakeRouter =
        IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IUniswapV2Router02 public constant spookyRouter =
        IUniswapV2Router02(address(0));

    uint8 internal constant DEPOSIT = 1;
    uint8 internal constant BATCH_DEPOSIT = 2; // Used for multi token and single token deposits
    uint8 internal constant WETH_DEPOSIT = 3;
    uint8 internal constant UNISWAP_INPUT_SINGLE = 4;
    uint8 internal constant UNISWAP_INPUT_MULTI = 5;
    uint8 internal constant SUSHI_LEGACY = 6;
    uint8 internal constant TRADERJOE_SWAP = 7;
    uint8 internal constant PANCAKE_SWAP = 8;
    uint8 internal constant SPOOKY_SWAP = 9;
    uint8 internal constant VELODROME = 10;
    uint8 internal constant SRC_TRANSFER = 11;
    uint8 internal constant STARGATE = 12;

    address public constant veloRouter =
        address(0x9c12939390052919aF3155f41Bf4160Fd3666A6f);

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    address public immutable weth; ///@notice on non eth or l2's this variable is simply wrapped native assets

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _weth,
        ISwapRouter _swapRouter,
        address _sushiFactory,
        bytes32 _sushiPairCodeHash,
        address _veloFactory,
        address _veloWeth,
        IStargateRouter _stargateRouter
    )
        UniswapAdapter(_swapRouter)
        SushiLegacyAdapter(_sushiFactory, _sushiPairCodeHash)
        StargateAdapter(_stargateRouter)
        VelodromeAdapter(_veloFactory, _veloWeth)
    {
        weth = _weth;
    }

    /*//////////////////////////////////////////////////////////////
                               CROSS-CHAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    ///@param steps one way array mapping steps with actions
    ///@param data one way array of data to perform at each called step
    function swaps(uint8[] memory steps, bytes[] memory data) external payable {
        for (uint256 i; i < steps.length; i++) {
            uint8 step = steps[i];
            if (step == DEPOSIT) {
                (address _token, uint256 _amount) = abi.decode(
                    data[i],
                    (address, uint256)
                );
                if (_amount <= 0) revert MoreThanZero();
                IERC20(_token).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _amount
                );
            } else if (step == BATCH_DEPOSIT) {
                (address[] memory tokens, uint256[] memory amounts) = abi
                    .decode(data[i], (address[], uint256[]));

                for (uint256 j; j < tokens.length; j++) {
                    if (amounts[j] <= 0) revert MoreThanZero();
                    IERC20(tokens[j]).safeTransferFrom(
                        msg.sender,
                        address(this),
                        amounts[j]
                    );
                }
            } else if (step == WETH_DEPOSIT) {
                uint256 _amount = abi.decode(data[i], (uint256));
                if (_amount <= 0) revert MoreThanZero();
                IWETH9(weth).deposit{value: _amount}();
            } else if (step == UNISWAP_INPUT_SINGLE) {
                (
                    uint256[] memory amountIn,
                    address[] memory token1,
                    address[] memory token2,
                    uint24[] memory poolFee
                ) = abi.decode(
                        data[i],
                        (uint256[], address[], address[], uint24[])
                    );
                for (uint256 j; j < amountIn.length; j++) {
                    swapExactInputSingle(
                        amountIn[j],
                        token1[j],
                        token2[j],
                        poolFee[j],
                        address(this)
                    );
                }
            } else if (step == UNISWAP_INPUT_MULTI) {
                (
                    uint256[] memory amountIn,
                    uint256[] memory amountOutMin,
                    address[] memory token1,
                    address[] memory token2,
                    address[] memory token3,
                    uint24[] memory fee1,
                    uint24[] memory fee2
                ) = abi.decode(
                        data[i],
                        (
                            uint256[],
                            uint256[],
                            address[],
                            address[],
                            address[],
                            uint24[],
                            uint24[]
                        )
                    );
                for (uint256 j; j < amountIn.length; j++) {
                    swapExactInputMultihop(
                        amountIn[j],
                        amountOutMin[j],
                        token1[j],
                        token2[j],
                        token3[j],
                        fee1[j],
                        fee2[j]
                    );
                }
            } else if (step == SUSHI_LEGACY) {
                (
                    uint256[] memory amountIn,
                    uint256[] memory amountOutMin,
                    address[][] memory path,
                    bool[] memory sendTokens
                ) = abi.decode(
                        data[i],
                        (uint256[], uint256[], address[][], bool[])
                    );
                for (uint256 j; j < amountIn.length; j++) {
                    _swapExactTokensForTokens(
                        amountIn[j],
                        amountOutMin[j],
                        path[j],
                        address(this),
                        sendTokens[j]
                    );
                }
            } else if (step == TRADERJOE_SWAP) {
                (
                    uint256[] memory amountIn,
                    uint256[] memory amountOutMin,
                    address[][] memory path,
                    uint256[] memory deadline
                ) = abi.decode(
                        data[i],
                        (uint256[], uint256[], address[][], uint256[])
                    );
                for (uint256 j; j < amountIn.length; j++) {
                    IERC20(path[j][0]).safeIncreaseAllowance(
                        address(joeRouter),
                        amountIn[j]
                    );
                    IJoeRouter02(joeRouter).swapExactTokensForTokens(
                        amountIn[j],
                        amountOutMin[j],
                        path[j],
                        address(this),
                        deadline[j]
                    );
                }
            } else if (step == PANCAKE_SWAP) {
                (
                    uint256[] memory amountIn,
                    uint256[] memory amountOutMin,
                    address[][] memory path,
                    uint256[] memory deadline
                ) = abi.decode(
                        data[i],
                        (uint256[], uint256[], address[][], uint256[])
                    );
                for (uint256 j; j < amountIn.length; j++) {
                    IERC20(path[j][0]).safeIncreaseAllowance(
                        address(pancakeRouter),
                        amountIn[j]
                    );
                    IPancakeRouter02(pancakeRouter).swapExactTokensForTokens(
                        amountIn[j],
                        amountOutMin[j],
                        path[j],
                        address(this),
                        deadline[j]
                    );
                }
            } else if (step == SPOOKY_SWAP) {
                (
                    uint256[] memory amountIn,
                    uint256[] memory amountOutMin,
                    address[][] memory path,
                    uint256[] memory deadline
                ) = abi.decode(
                        data[i],
                        (uint256[], uint256[], address[][], uint256[])
                    );
                for (uint256 j; j < amountIn.length; j++) {
                    IERC20(path[j][0]).safeIncreaseAllowance(
                        address(spookyRouter),
                        amountIn[j]
                    );
                    IUniswapV2Router02(spookyRouter).swapExactTokensForTokens(
                        amountIn[j],
                        amountOutMin[j],
                        path[j],
                        address(this),
                        deadline[j]
                    );
                }
            } else if (step == VELODROME) {
                VeloParams[] memory params = abi.decode(
                    data[i],
                    (VeloParams[])
                );
                for (uint256 j; j < params.length; j++) {
                    IERC20(params[j].routes[0].from).safeIncreaseAllowance(
                        veloRouter,
                        params[j].amountIn
                    );
                    veloSwapExactTokensForTokens(params[j]);
                }
            } else if (step == SRC_TRANSFER) {
                SrcTransferParams memory params = abi.decode(
                    data[i],
                    (SrcTransferParams)
                );
                for (uint256 k; k < params.tokens.length; k++) {
                    address token = params.tokens[k];
                    uint256 amount = IERC20(token).balanceOf(address(this));
                    uint256 fee = calculateFee(amount);
                    amount -= fee;
                    IERC20(token).safeTransfer(feeCollector, fee);
                    IERC20(token).safeTransfer(params.to, amount);
                    emit FeePaid(token, fee);
                }
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

    function version() external pure returns (string memory _version) {
        _version = "0.0.3";
    }

    receive() external payable {}
}
