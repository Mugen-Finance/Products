//SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "../../adapters/SushiAdapter.sol";
import {IFantomSwaps} from "./interfaces/IFantomSwaps.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWETH9} from "../../interfaces/IWETH9.sol";
import {IUniswapV2Router02} from "spookyswap/contracts/interfaces/IUniswapV2Router02.sol";
import "./StargateFantom.sol";

contract PolygonSwaps is SushiLegacyAdapter, StargateFantom, IFantomSwaps  {

    IWETH9 internal immutable weth;

    constructor(IWETH9 _weth, address _factory, bytes32 _pairCodeHash, IStargateRouter _stargateRouter) 
   
    SushiLegacyAdapter(_factory, _pairCodeHash) 
    StargateFantom(_stargateRouter) 
    {
        weth = _weth;
    }

    function fantomSwaps(uint8[] calldata steps, bytes[] calldata data) external payable {}

    receive() external payable {}
}