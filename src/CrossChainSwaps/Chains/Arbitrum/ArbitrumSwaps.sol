//SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "../../adapters/UniswapAdapter.sol";
import "../../adapters/SushiAdapter.sol";
import "../../adapters/XCaliburAdapter.sol";
import {IWETH9} from "../../interfaces/IWETH9.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IArbitrumSwaps} from "./interfaces/IArbitrumSwaps.sol";

contract ArbitrumSwaps is UniswapAdapter, SushiLegacyAdapter, IArbitrumSwaps {

    IWETH9 internal immutable weth;

    //Constants

    uint8 internal constant BATCH_DEPOSIT = 1;
    uint8 internal constant WETH_DEPOSIT = 2;
    uint8 internal constant UNI_SINGLE = 3;
    uint8 internal constant UNI_MULTI = 4;
    uint8 internal constant SUSHI_LEGACY = 5;
    uint8 internal constant SUSHI_TRIDENT = 6;
    uint8 internal constant XCAL = 7;
    uint8 internal constant SRC_TRANSFER = 8;
    uint8 internal constant WETH_WITHDRAW = 9;
    uint8 internal constant STARGATE = 10;

    constructor(IWETH9 _weth, ISwapRouter _swapRouter, address _factory, bytes32 _pairCodeHash, address _factory) 
    UniswapAdapter(_swapRouter)
    SushiLegacyAdapter(_factory, _pairCodeHash) 
    XCaliburAdapter(_factory, _weth)
    {
        weth = _weth;
    }

    function arbitrumSwaps(uint8[] calldata steps, bytes[] calldata data) external payable {}

    receive() external payable {}
}