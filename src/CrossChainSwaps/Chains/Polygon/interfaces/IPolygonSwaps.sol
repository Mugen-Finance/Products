//SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;



interface IPolygonSwaps  {
    function polygonSwaps(uint8[] calldata, bytes[] calldata) external payable;
}