//SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "../../adapters/SushiAdapter.sol";
import {IPancakeRouter02} from "pancake/projects/exchange-protocol/contracts/interfaces/IPancakeRouter02.sol";
import {IBinanceSwaps} from "./interfaces/IBinanceSwaps.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWETH9} from "../../interfaces/IWETH9.sol";
import {IJoeRouter02} from "traderjoe/contracts/traderjoe/interfaces/IJoeRouter02.sol";
import "./StargateBinance.sol";

contract PolygonSwaps is SushiLegacyAdapter, StargateBinance, IBinanceSwaps  {

    IWETH9 internal immutable weth;
    IPancakeRouter02 internal immutable pancakeRouter;

    constructor(IWETH9 _weth, address _factory, bytes32 _pairCodeHash, IStargateRouter _stargateRouter, IPancakeRouter02 _pancakeRouter) 
    SushiLegacyAdapter(_factory, _pairCodeHash) 
    StargateBinance(_stargateRouter) 
    {
        weth = _weth;
        pancakeRouter = _pancakeRouter;
    }

    function binanceSwaps(uint8[] calldata steps, bytes[] calldata data) external payable {}

    receive() external payable {}
}