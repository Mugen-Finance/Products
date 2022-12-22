//SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "../../adapters/SushiAdapter.sol";
import "../../adapters/VelodromeAdapter.sol";
import "../../adapters/UniswapAdapter.sol";
import "./StargateOptimism.sol";
import {IOptimismSwaps} from "./interfaces/IOptimismSwaps.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWETH9} from "../../interfaces/IWETH9.sol";

contract OptimismSwaps is UniswapAdapter, SushiLegacyAdapter, VelodromeAdapter, StargateOptimism, IOptimismSwaps {
    using SafeERC20 for IERC20;

    error MoreThanZero();
    error WithdrawFailed();

    event SuccessfulWithdraw(bool success);

    IWETH9 internal immutable weth;
    address public immutable feeCollector;

    uint8 private locked = 1;

    modifier lock() {
        require(locked == 1, "REENTRANCY");
        locked = 2;
        _;
        locked = 1;
    }

    struct SrcTransferParams {
        address token;
        address receiver;
        uint256 amount;
    }

    //Constants

    uint8 internal constant BATCH_DEPOSIT = 1; // Used for multi token and single token deposits
    uint8 internal constant WETH_DEPOSIT = 2;
    uint8 internal constant UNISWAP_INPUT_SINGLE = 3;
    uint8 internal constant UNISWAP_INPUT_MULTI = 4;
    uint8 internal constant SUSHI_LEGACY = 5;
    uint8 internal constant VELODROME = 9;
    uint8 internal constant SRC_TRANSFER = 11;
    uint8 internal constant WETH_WITHDRAW = 12;
    uint8 internal constant STARGATE = 13;

    constructor(
        IWETH9 _weth,
        address _feeCollector,
        ISwapRouter _swapRouter,
        address _factory,
        bytes32 _pairCodeHash,
        IStargateRouter _stargateRouter
    )
        UniswapAdapter(_swapRouter)
        SushiLegacyAdapter(_factory, _pairCodeHash)
        VelodromeAdapter()
        StargateOptimism(_stargateRouter)
    {
        weth = _weth;
        feeCollector = _feeCollector;
    }

    function optimismSwaps(uint8[] calldata steps, bytes[] calldata data) external payable lock {
        for (uint256 i; i < steps.length; i++) {
            uint8 step = steps[i];
            if (step == BATCH_DEPOSIT) {
                (address[] memory tokens, uint256[] memory amounts) = abi.decode(data[i], (address[], uint256[]));

                for (uint256 j; j < tokens.length; j++) {
                    if (amounts[j] <= 0) revert MoreThanZero();
                    IERC20(tokens[j]).safeTransferFrom(msg.sender, address(this), amounts[j]);
                }
            } else if (step == WETH_DEPOSIT) {
                uint256 _amount = abi.decode(data[i], (uint256));
                if (_amount <= 0) revert MoreThanZero();
                IWETH9(weth).deposit{value: _amount}();
            } else if (step == UNISWAP_INPUT_SINGLE) {
                UniswapV3Single[] memory params = abi.decode(data[i], (UniswapV3Single[]));
                for (uint256 j; j < params.length; j++) {
                    UniswapV3Single memory swapData = params[j];
                    swapExactInputSingle(swapData);
                }
            } else if (step == UNISWAP_INPUT_MULTI) {
                UniswapV3Multi[] memory params = abi.decode(data[i], (UniswapV3Multi[]));
                for (uint256 j; j < params.length; j++) {
                    swapExactInputMultihop(params[j]);
                }
            } else if (step == SUSHI_LEGACY) {
                SushiParams[] memory params = abi.decode(data[i], (SushiParams[]));
                for (uint256 j; j < params.length; j++) {
                    _swapExactTokensForTokens(params[j]);
                }
            } else if (step == VELODROME) {
                VeloParams[] memory params = abi.decode(data[i], (VeloParams[]));
                for (uint256 j; j < params.length; j++) {
                    IERC20(params[j].routes[0].from).safeIncreaseAllowance(veloRouter, params[j].amountIn);
                    veloSwapExactTokensForTokens(params[j]);
                }
            } else if (step == SRC_TRANSFER) {
                SrcTransferParams[] memory params = abi.decode(data[i], (SrcTransferParams[]));

                for (uint256 k; k < params.length; k++) {
                    _srcTransfer(params[k].token, params[k].amount, params[k].receiver);
                }
            } else if (step == WETH_WITHDRAW) {
                (address to, uint256 amount) = abi.decode(data[i], (address, uint256));
                amount = amount != 0 ? amount : IERC20(weth).balanceOf(address(this));
                weth.withdraw(amount);
                (bool success,) = to.call{value: amount}("");
                if (!success) revert WithdrawFailed();
                emit SuccessfulWithdraw(success);
            } else if (step == STARGATE) {
                (StargateParams memory params, uint8[] memory stepperions, bytes[] memory datass) =
                    abi.decode(data[i], (StargateParams, uint8[], bytes[]));
                stargateSwap(params, stepperions, datass);
            }
        }
    }

    function _srcTransfer(address _token, uint256 amount, address to) private {
        amount = amount != 0 ? amount : IERC20(_token).balanceOf(address(this));
        uint256 fee = calculateFee(amount);
        amount -= fee;
        IERC20(_token).safeTransfer(feeCollector, fee);
        IERC20(_token).safeTransfer(to, amount);
        emit FeePaid(_token, fee);
    }

    receive() external payable {}
}
