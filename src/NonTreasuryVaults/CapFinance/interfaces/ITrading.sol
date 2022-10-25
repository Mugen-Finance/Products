//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface ITrading {
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

    // Internal methods

    // function _getPositionKey(
    //     address user,
    //     bytes32 productId,
    //     address currency,
    //     bool isLong
    // ) internal pure returns (bytes32) {
    //     return keccak256(abi.encodePacked(user, productId, currency, isLong));
    // }

    // function _getPnL(
    //     bool isLong,
    //     uint256 price,
    //     uint256 positionPrice,
    //     uint256 size,
    //     uint256 interest,
    //     uint256 timestamp
    // ) internal view returns (int256 _pnl) {
    //     bool pnlIsNegative;
    //     uint256 pnl;

    //     if (isLong) {
    //         if (price >= positionPrice) {
    //             pnl = (size * (price - positionPrice)) / positionPrice;
    //         } else {
    //             pnl = (size * (positionPrice - price)) / positionPrice;
    //             pnlIsNegative = true;
    //         }
    //     } else {
    //         if (price > positionPrice) {
    //             pnl = (size * (price - positionPrice)) / positionPrice;
    //             pnlIsNegative = true;
    //         } else {
    //             pnl = (size * (positionPrice - price)) / positionPrice;
    //         }
    //     }

    //     // Subtract interest from P/L
    //     if (block.timestamp >= timestamp + 15 minutes) {
    //         uint256 _interest = (size *
    //             interest *
    //             (block.timestamp - timestamp)) / (UNIT * 10**4 * 360 days);

    //         if (pnlIsNegative) {
    //             pnl += _interest;
    //         } else if (pnl < _interest) {
    //             pnl = _interest - pnl;
    //             pnlIsNegative = true;
    //         } else {
    //             pnl -= _interest;
    //         }
    //     }

    //     if (pnlIsNegative) {
    //         _pnl = -1 * int256(pnl);
    //     } else {
    //         _pnl = int256(pnl);
    //     }

    //     return _pnl;
    // }

    // // Getters

    // function getProduct(bytes32 productId)
    //     external
    //     view
    //     returns (Product memory)
    // {
    //     return products[productId];
    // }

    // function getPosition(
    //     address user,
    //     address currency,
    //     bytes32 productId,
    //     bool isLong
    // ) external view returns (Position memory position) {
    //     bytes32 key = _getPositionKey(user, productId, currency, isLong);
    //     return positions[key];
    // }

    // function getOrder(
    //     address user,
    //     address currency,
    //     bytes32 productId,
    //     bool isLong
    // ) external view returns (Order memory order) {
    //     bytes32 key = _getPositionKey(user, productId, currency, isLong);
    //     return orders[key];
    // }

    // function getOrders(bytes32[] calldata keys)
    //     external
    //     view
    //     returns (Order[] memory _orders)
    // {
    //     uint256 length = keys.length;
    //     _orders = new Order[](length);
    //     for (uint256 i = 0; i < length; i++) {
    //         _orders[i] = orders[keys[i]];
    //     }
    //     return _orders;
    // }

    // function getPositions(bytes32[] calldata keys)
    //     external
    //     view
    //     returns (Position[] memory _positions)
    // {
    //     uint256 length = keys.length;
    //     _positions = new Position[](length);
    //     for (uint256 i = 0; i < length; i++) {
    //         _positions[i] = positions[keys[i]];
    //     }
    //     return _positions;
    // }

    // function getPendingFee(address currency) external view returns (uint256) {
    //     return pendingFees[currency] * 10**(18 - UNIT_DECIMALS);
    // }

    // function _getPnL(
    //     bool isLong,
    //     uint256 price,
    //     uint256 positionPrice,
    //     uint256 size,
    //     uint256 interest,
    //     uint256 timestamp
    // ) internal view returns (int256 _pnl) {
    //     bool pnlIsNegative;
    //     uint256 pnl;

    //     if (isLong) {
    //         if (price >= positionPrice) {
    //             pnl = (size * (price - positionPrice)) / positionPrice;
    //         } else {
    //             pnl = (size * (positionPrice - price)) / positionPrice;
    //             pnlIsNegative = true;
    //         }
    //     } else {
    //         if (price > positionPrice) {
    //             pnl = (size * (price - positionPrice)) / positionPrice;
    //             pnlIsNegative = true;
    //         } else {
    //             pnl = (size * (positionPrice - price)) / positionPrice;
    //         }
    //     }

    //     // Subtract interest from P/L
    //     if (block.timestamp >= timestamp + 15 minutes) {
    //         uint256 _interest = (size *
    //             interest *
    //             (block.timestamp - timestamp)) / (UNIT * 10**4 * 360 days);

    //         if (pnlIsNegative) {
    //             pnl += _interest;
    //         } else if (pnl < _interest) {
    //             pnl = _interest - pnl;
    //             pnlIsNegative = true;
    //         } else {
    //             pnl -= _interest;
    //         }
    //     }

    //     if (pnlIsNegative) {
    //         _pnl = -1 * int256(pnl);
    //     } else {
    //         _pnl = int256(pnl);
    //     }

    //     return _pnl;
    // }
}
