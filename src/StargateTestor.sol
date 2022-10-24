//SPDX-License-Identifier-MIT

pragma solidity 0.8.15;

import {IStargateReceiver} from "./CrossChainSwaps/interfaces/IStargateReceiver.sol";
import {IStargateRouter} from "./CrossChainSwaps/interfaces/IStargateRouter.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StargateTestor is IStargateReceiver {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ///@notice address of the stargate router
    IStargateRouter public immutable stargateRouter;

    ///@notice address of the wallet to collect fees
    address public immutable feeCollector;

    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/

    event ReceivedOnDestination(
        address indexed token,
        uint256 amountLD,
        bool failed
    );

    error NotStgRouter();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IStargateRouter _stargateRouter) {
        stargateRouter = _stargateRouter;
        feeCollector = msg.sender;
    }

    ///@notice struct to define parameters needed for the swap.
    struct StargateParams {
        uint16 dstChainId; // stargate dst chain id
        address token; // token getting bridged
        uint256 srcPoolId; // stargate src pool id
        uint256 dstPoolId; // stargate dst pool id
        uint256 amount; // amount to bridge
        uint256 amountMin; // amount to bridge minimum
        uint256 dustAmount; // native token to be received on dst chain
        address receiver; // Mugen contract on dst chain
        address to; // receiver bridge token incase of transaction reverts on dst chain
        uint256 gas; // extra gas to be sent for dst chain operations
        bytes32 srcContext; // random bytes32 as source context
    }

    /*//////////////////////////////////////////////////////////////
                               INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @param params parameters for the stargate router defined in StargateParams

    function stargateSwap(StargateParams memory params) external payable {
        IERC20(params.token).safeTransferFrom(
            msg.sender,
            address(this),
            params.amount
        );
        bytes memory payload = abi.encode(params.to);
        IERC20(params.token).safeIncreaseAllowance(
            address(stargateRouter),
            params.amount
        );
        IStargateRouter(stargateRouter).swap{value: msg.value}(
            params.dstChainId,
            params.srcPoolId,
            params.dstPoolId,
            payable(msg.sender),
            params.amount != 0
                ? params.amount
                : IERC20(params.token).balanceOf(address(this)),
            params.amountMin,
            IStargateRouter.lzTxObj(200000, 0, "0x"),
            abi.encodePacked(params.receiver),
            payload
        );
    }

    /*//////////////////////////////////////////////////////////////
                               STARGATE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @param _token The token contract on the local chain
    /// @param amountLD The qty of local _token contract tokens
    /// @param _payload The bytes containing the toAddress
    function sgReceive(
        uint16,
        bytes memory,
        uint256,
        address _token,
        uint256 amountLD,
        bytes memory _payload
    ) external override {
        string memory _data = "you have liftoff";
    }
}
