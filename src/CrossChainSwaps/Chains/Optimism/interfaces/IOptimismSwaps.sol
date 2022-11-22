//SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

interface IOptimismSwaps {
    function optimismSwaps(uint8[] calldata, bytes[] calldata) external payable;
}
