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

//change things to an array of structs
// Pack structs

contract CrossChainSwaps is
    UniswapAdapter,
    SushiLegacyAdapter,
    StargateAdapter,
    VelodromeAdapter
{
    using SafeERC20 for IERC20;

    error NotEnoughSteps();
    error MoreThanZero();

    // =================================================|
    // ====================== STRUCTS ==================|
    // =================================================|

    struct SrcTransferParams {
        address token;
        address receiver;
        uint256 amount;
    }

    struct UniswapV2Params {
        uint256 amountIn;
        uint256 amountOutMin;
        address[] path;
        uint256 deadline;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    //Router Constants

    IJoeRouter02 public constant joeRouter = IJoeRouter02(address(0x60aE616a2155Ee3d9A68541Ba4544862310933d4));
    IPancakeRouter02 public constant pancakeRouter =
        IPancakeRouter02(address(0));
    IUniswapV2Router02 public constant spookyRouter =
        IUniswapV2Router02(address(0));

    // Step Constants

    uint8 internal constant BATCH_DEPOSIT = 1; // Used for multi token and single token deposits
    uint8 internal constant WETH_DEPOSIT = 2;
    uint8 internal constant UNISWAP_INPUT_SINGLE = 3;
    uint8 internal constant UNISWAP_INPUT_MULTI = 4;
    uint8 internal constant SUSHI_LEGACY = 5;
    uint8 internal constant TRADERJOE_SWAP = 6;
    uint8 internal constant PANCAKE_SWAP = 7;
    uint8 internal constant SPOOKY_SWAP = 8;
    uint8 internal constant VELODROME = 9;
    uint8 internal constant SRC_TRANSFER = 10; // Done after all swaps are completed to ease accounting
    uint8 internal constant STARGATE = 11;

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
    function swaps(uint8[] calldata steps, bytes[] calldata data)
        external
        payable
    {
        for (uint256 i; i < steps.length; i++) {
            uint8 step = steps[i];
            if (step == BATCH_DEPOSIT) {
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
                UniswapV3Single[] memory params = abi.decode(
                    data[i],
                    (UniswapV3Single[])
                );
                for (uint256 j; j < params.length; j++) {
                    UniswapV3Single memory swapData = params[j];
                    swapExactInputSingle(swapData);
                }
            } else if (step == UNISWAP_INPUT_MULTI) {
                UniswapV3Multi[] memory params = abi.decode(
                    data[i],
                    (UniswapV3Multi[])
                );
                for (uint256 j; j < params.length; j++) {
                    
                    swapExactInputMultihop(params[j]);
                }
            } else if (step == SUSHI_LEGACY) {
                SushiParams[] memory params = abi.decode(
                    data[i],
                    (SushiParams[])
                );
                for (uint256 j; j < params.length; j++) {
                    _swapExactTokensForTokens(params[j]);
                }
            } else if (step == TRADERJOE_SWAP) {
                UniswapV2Params[] memory params = abi.decode(
                    data[i],
                    (UniswapV2Params[])
                );
                for (uint256 j; j < params.length; j++) {
                    IERC20(params[j].path[0]).safeIncreaseAllowance(
                        address(joeRouter),
                        params[j].amountIn
                    );
                    IJoeRouter02(joeRouter).swapExactTokensForTokens(
                        params[j].amountIn,
                        params[j].amountOutMin,
                        params[j].path,
                        address(this),
                        params[j].deadline
                    );
                }
            } else if (step == PANCAKE_SWAP) {
                UniswapV2Params[] memory params = abi.decode(
                    data[i],
                    (UniswapV2Params[])
                );
                for (uint256 j; j < params.length; j++) {
                    IERC20(params[j].path[0]).safeIncreaseAllowance(
                        address(pancakeRouter),
                        params[j].amountIn
                    );
                    IPancakeRouter02(pancakeRouter).swapExactTokensForTokens(
                        params[j].amountIn,
                        params[j].amountOutMin,
                        params[j].path,
                        address(this),
                        params[j].deadline
                    );
                }
            } else if (step == SPOOKY_SWAP) {
                UniswapV2Params[] memory params = abi.decode(
                    data[i],
                    (UniswapV2Params[])
                );
                for (uint256 j; j < params.length; j++) {
                    IERC20(params[j].path[0]).safeIncreaseAllowance(
                        address(spookyRouter),
                        params[j].amountIn
                    );
                    IUniswapV2Router02(spookyRouter).swapExactTokensForTokens(
                        params[j].amountIn,
                        params[j].amountOutMin,
                        params[j].path,
                        address(this),
                        params[j].deadline
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
                SrcTransferParams[] memory params = abi.decode(
                    data[i],
                    (SrcTransferParams[])
                );

                for (uint256 k; k < params.length; k++) {
                    address token = params[k].token;
                    uint256 amount = params[k].amount;
                    amount = amount != 0
                        ? amount
                        : IERC20(token).balanceOf(address(this));
                    address to = params[k].receiver;
                    uint256 fee = calculateFee(amount);
                    amount -= fee;
                    IERC20(token).safeTransfer(feeCollector, fee);
                    IERC20(token).safeTransfer(to, amount);
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
        _version = "0.0.4";
    }

    receive() external payable {}
}
