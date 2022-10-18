//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface ICrossChainSwaps {
    function swaps(uint8[] memory steps, bytes[] memory data) external payable;
}
