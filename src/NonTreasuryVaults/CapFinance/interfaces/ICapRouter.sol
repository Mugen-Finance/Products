// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICapRouter {
    function isSupportedCurrency(address currency) external view returns (bool);

    function currenciesLength() external view returns (uint256);

    function getPool(address currency) external view returns (address);

    function getPoolShare(address currency) external view returns (uint256);

    function getCapShare(address currency) external view returns (uint256);

    function getPoolRewards(address currency) external view returns (address);

    function getCapRewards(address currency) external view returns (address);

    function getDecimals(address currency) external view returns (uint8);
}
