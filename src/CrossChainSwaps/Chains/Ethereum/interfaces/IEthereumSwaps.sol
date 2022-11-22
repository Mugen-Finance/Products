//SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

interface IEthereumSwaps {
    function ethereumSwaps(uint8[] calldata, bytes[] calldata) external payable;
}
