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

    error MustBeGt0();

    event FeePaid(uint256 _fee);

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    //Change these for testnet

    IJoeRouter02 public constant joeRouter =
        IJoeRouter02(0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901);
    IPancakeRouter02 public constant pancakeRouter =
        IPancakeRouter02(address(0));
    IUniswapV2Router02 public constant spookyRouter =
        IUniswapV2Router02(address(0));
    address public constant veloRouter =
        0x9c12939390052919aF3155f41Bf4160Fd3666A6f;
    uint8 internal constant DEPOSIT = 1;
    uint8 internal constant WETH_DEPOSIT = 2;
    uint8 internal constant UNISWAP_INPUT_SINGLE = 3;
    uint8 internal constant UNISWAP_INPUT_MULTI = 4;
    uint8 internal constant SUSHI_LEGACY = 5;
    uint8 internal constant TRADERJOE_SWAP = 6;
    uint8 internal constant PANCAKE_SWAP = 7;
    uint8 internal constant SPOOKY_SWAP = 8;
    uint8 internal constant VELODROME = 9;
    uint8 internal constant STARGATE = 10;

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
                uint256 _fee = fee(_amount);
                IERC20(_token).safeTransfer(feeCollector, _fee);
            } else if (step == WETH_DEPOSIT) {
                uint256 _amount = abi.decode(data[i], (uint256));
                uint256 _fee = fee(_amount);
                payable(feeCollector).call{value: _fee}("");
                _amount = _amount - _fee;
                IWETH9(weth).deposit{value: _amount}();
                emit FeePaid(_fee);
            } else if (step == UNISWAP_INPUT_SINGLE) {
                (
                    uint256 amountIn,
                    address token1,
                    address token2,
                    uint24 poolFee,
                    address to
                ) = abi.decode(
                        data[i],
                        (uint256, address, address, uint24, address)
                    );
                swapExactInputSingle(amountIn, token1, token2, poolFee, to);
            } else if (step == UNISWAP_INPUT_MULTI) {
                (
                    uint256 amountIn,
                    uint256 amountOutMin,
                    address token1,
                    address token2,
                    address token3,
                    uint24 fee1,
                    uint24 fee2,
                    address to
                ) = abi.decode(
                        data[i],
                        (
                            uint256,
                            uint256,
                            address,
                            address,
                            address,
                            uint24,
                            uint24,
                            address
                        )
                    );
                swapExactInputMultihop(
                    amountIn,
                    amountOutMin,
                    token1,
                    token2,
                    token3,
                    fee1,
                    fee2,
                    to
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
            } else if (step == VELODROME) {
                (
                    uint256 amountIn,
                    uint256 amountOutMin,
                    route[] memory routes,
                    address to,
                    uint256 deadline
                ) = abi.decode(
                        data[i],
                        (uint256, uint256, route[], address, uint256)
                    );
                IERC20(routes[0].from).safeIncreaseAllowance(
                    veloRouter,
                    amountIn
                );
                veloSwapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    routes,
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

    function version() external pure returns (string memory _version) {
        _version = "0.0.1";
    }

    /*//////////////////////////////////////////////////////////////
                               INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function fee(uint256 amount) internal pure returns (uint256 _fee) {
        _fee = (amount * 5) / 10000;
    }

    receive() external payable {}
}
