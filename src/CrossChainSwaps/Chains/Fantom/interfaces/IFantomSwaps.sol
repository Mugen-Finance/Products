//SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

interface IFantomSwaps {
    function fantomSwaps(uint8[] calldata, bytes[] calldata) external payable;
}
