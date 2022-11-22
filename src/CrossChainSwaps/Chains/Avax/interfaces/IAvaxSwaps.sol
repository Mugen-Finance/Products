//SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

interface IAvaxSwaps {
    function avaxSwaps(uint8[] calldata, bytes[] calldata) external payable;
}
