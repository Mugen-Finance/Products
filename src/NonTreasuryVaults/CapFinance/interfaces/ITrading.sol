//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface ITrading {
    // All amounts in 8 decimals unless otherwise indicated

    // Methods

    function distributeFees(address currency) external;

    function submitOrder(
        bytes32 productId,
        address currency,
        bool isLong,
        uint256 margin,
        uint256 size
    ) external payable;

    function submitCloseOrder(
        bytes32 productId,
        address currency,
        bool isLong,
        uint256 size
    ) external payable;

    function cancelOrder(
        bytes32 productId,
        address currency,
        bool isLong
    ) external;
}
