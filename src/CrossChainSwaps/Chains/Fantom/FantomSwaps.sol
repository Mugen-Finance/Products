//SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "../../adapters/SushiAdapter.sol";
import {IFantomSwaps} from "./interfaces/IFantomSwaps.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWETH9} from "../../interfaces/IWETH9.sol";
import {IUniswapV2Router02} from "spookyswap/contracts/interfaces/IUniswapV2Router02.sol";
import "./StargateFantom.sol";

contract PolygonSwaps is SushiAdapter, StargateFantom, IFantomSwaps {
    using SafeERC20 for IERC20;

    error MoreThanZero();
    error WithdrawFailed();

    event SuccessfulWithdraw(bool success);

    IWETH9 internal immutable weth;
    address public immutable feeCollector;
    IUniswapV2Router02 internal immutable spookyRouter;

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

    struct UniswapV2Params {
        uint256 amountIn;
        uint256 amountOutMin;
        address[] path;
        uint256 deadline;
    }

    // Contants

    uint8 internal constant BATCH_DEPOSIT = 1; // Used for multi token and single token deposits
    uint8 internal constant WETH_DEPOSIT = 2;
    uint8 internal constant SUSHI_LEGACY = 5;
    uint8 internal constant SPOOKY_SWAP = 9;
    uint8 internal constant WETH_WITHDRAW = 13;
    uint8 internal constant SRC_TRANSFER = 14; // Done after all swaps are completed to ease accounting
    uint8 internal constant STARGATE = 15;

    constructor(
        IWETH9 _weth,
        address _feeCollector,
        address _spookyRouter,
        address _factory,
        bytes32 _pairCodeHash,
        IStargateRouter _stargateRouter
    ) SushiAdapter(_factory, _pairCodeHash) StargateFantom(_stargateRouter) {
        weth = _weth;
        feeCollector = _feeCollector;
        spookyRouter = IUniswapV2Router02(_spookyRouter);
    }

    function fantomSwaps(uint8[] calldata steps, bytes[] calldata data) external payable lock {
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
            } else if (step == SUSHI_LEGACY) {
                SushiParams[] memory params = abi.decode(data[i], (SushiParams[]));
                for (uint256 j; j < params.length; j++) {
                    _swapExactTokensForTokens(params[j]);
                }
            } else if (step == SPOOKY_SWAP) {
                UniswapV2Params[] memory params = abi.decode(data[i], (UniswapV2Params[]));
                for (uint256 j; j < params.length; j++) {
                    IERC20(params[j].path[0]).safeIncreaseAllowance(address(spookyRouter), params[j].amountIn);
                    IUniswapV2Router02(spookyRouter).swapExactTokensForTokens(
                        params[j].amountIn, params[j].amountOutMin, params[j].path, address(this), params[j].deadline
                    );
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
