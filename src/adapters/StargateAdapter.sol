//SPDX-License-Identifier-MIT

pragma solidity 0.8.15;

import {IStargateReceiver} from "../interfaces/IStargateReceiver.sol";
import {IStargateRouter} from "../interfaces/IStargateRouter.sol";
import {ICrossChainSwaps} from "../interfaces/ICrossChainSwaps.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";

//{ICrossChainSwaps} from

abstract contract StargateAdapter is IStargateReceiver {
    IStargateRouter public immutable stargateRouter;

    constructor(IStargateRouter _stargateRouter) {
        stargateRouter = _stargateRouter;
    }

    struct StargateParams {
        uint16 dstChainId; // stargate dst chain id
        address token; // token getting bridged
        uint256 srcPoolId; // stargate src pool id
        uint256 dstPoolId; // stargate dst pool id
        uint256 amount; // amount to bridge
        uint256 amountMin; // amount to bridge minimum
        uint256 dustAmount; // native token to be received on dst chain
        address receiver; // sushiXswap on dst chain
        address to; // receiver bridge token incase of transaction reverts on dst chain
        uint256 gas; // extra gas to be sent for dst chain operations
        bytes32 srcContext; // random bytes32 as source context
    }

    function stargateSwap(
        StargateParams memory params,
        uint8[] memory stepsDst,
        bytes[] memory dataDst
    ) internal {
        bytes memory payload = abi.encode(stepsDst, dataDst);
        IStargateRouter(stargateRouter).swap(
            params.dstChainId,
            params.srcPoolId,
            params.dstPoolId,
            payable(msg.sender),
            params.amount != 0
                ? params.amount
                : IERC20(params.token).balanceOf(address(this)),
            params.amountMin,
            IStargateRouter.lzTxObj(
                params.gas,
                params.dustAmount,
                abi.encodePacked(params.receiver)
            ),
            abi.encodePacked(params.receiver),
            payload
        );
    }

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
        require(
            msg.sender == address(stargateRouter),
            "only stargate router can call sgReceive!"
        );
        (address to, uint8[] memory steps, bytes[] memory data) = abi.decode(
            _payload,
            (address, uint8[], bytes[])
        );
        bool failed;
        try
            ICrossChainSwaps(payable(address(this))).swaps(steps, data)
        {} catch (bytes memory) {
            IERC20(_token).transfer(to, amountLD);
            failed = true;
        }
        //emit ReceivedOnDestination(_token, amountLD);
    }
}
