// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IETHPool {
    // Methods

    function deposit(uint256 amount) external payable;

    function withdraw(uint256 currencyAmount) external;

    // Getters

    function getCurrencyBalance(address account)
        external
        view
        returns (uint256);

    // In Clp
    function getBalance(address account) external view returns (uint256);
}
