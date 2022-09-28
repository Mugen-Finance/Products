//SPDX-License-Identifier-MIT

pragma solidity 0.8.15;

import {IStargateReceiver} from "../interfaces/IStargateReceiver.sol";
import {IStargateRouter} from "../interfaces/IStargateRouter.sol";
import "../interfaces/ICrossChainSwaps.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";

//{ICrossChainSwaps} from

abstract contract StargateAdapter is IStargateReceiver {
    IStargateRouter public immutable stargateRouter;

    constructor(IStargateRouter _stargateRouter) {
        stargateRouter = _stargateRouter;
    }

    struct StargateParams {
        uint16 dstChainId;
        uint256 srcPoolId;
        uint256 dstPoolId;
        address payable refundAddress;
        uint256 amountLD;
        uint256 minAmountLD;
        uint256 dstGas;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
        address destinationAddress;
    }

    function stargateSwap(
        StargateParams memory params,
        uint8[] memory stepsDst,
        bytes[] memory dataDst
    ) public payable {
        bytes memory dstDestinationAddress = abi.encodePacked(
            params.destinationAddress
        );
        bytes memory payload = abi.encode(stepsDst, dataDst);
        IStargateRouter(stargateRouter).swap(
            params.dstChainId,
            params.srcPoolId,
            params.dstPoolId,
            params.refundAddress,
            params.amountLD,
            params.minAmountLD,
            IStargateRouter.lzTxObj(
                params.dstGas,
                params.dstNativeAmount,
                params.dstNativeAddr
            ),
            dstDestinationAddress,
            payload
        );
    }

    /// @param _chainId The remote chainId sending the tokens
    /// @param _srcAddress The remote Bridge address
    /// @param _nonce The message ordering nonce
    /// @param _token The token contract on the local chain
    /// @param amountLD The qty of local _token contract tokens
    /// @param _payload The bytes containing the toAddress
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory _payload
    ) external override {
        require(
            msg.sender == address(stargateRouter),
            "only stargate router can call sgReceive!"
        );
        (address _toAddr, uint8[] memory steps, bytes[] memory data) = abi
            .decode(_payload, (address, uint8[], bytes[]));
        ICrossChainSwaps(payable(address(this))).swaps(steps, data); //Why does this work?
        IERC20(_token).transfer(_toAddr, amountLD);
        //emit ReceivedOnDestination(_token, amountLD);
    }
}
