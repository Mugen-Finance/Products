//SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "../../adapters/SushiAdapter.sol";
import "../../adapters/VelodromeAdapter.sol";
import "../../adapters/UniswapAdapter.sol";
import "./StargateOptimism.sol";
import {IOptimismSwaps} from "./interfaces/IOptimismSwaps.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWETH9} from "../../interfaces/IWETH9.sol";
import {IJoeRouter02} from "traderjoe/contracts/traderjoe/interfaces/IJoeRouter02.sol";

contract AvaxSwaps is UniswapAdapter, SushiLegacyAdapter, VelodromeAdapter, StargateOptimism, IOptimismSwaps {

    IWETH9 internal immutable weth;

    constructor(IWETH9 _weth, ISwapRouter _swapRouter, address _factory, bytes32 _pairCodeHash, IStargateRouter _stargateRouter) 
    UniswapAdapter(_swapRouter) 
    SushiLegacyAdapter(_factory, _pairCodeHash) 
    VelodromeAdapter() 
    StargateOptimism(_stargateRouter)
    {
        weth = _weth;
    }

    function optimismSwaps(uint8[] calldata steps, bytes[] calldata data) external payable {}

    receive() external payable {}
}