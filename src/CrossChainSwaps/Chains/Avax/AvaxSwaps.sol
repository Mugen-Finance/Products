//SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "../../adapters/SushiAdapter.sol";
import {IAvaxSwaps} from "./interfaces/IAvaxSwaps.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWETH9} from "../../interfaces/IWETH9.sol";
import {IJoeRouter02} from "traderjoe/contracts/traderjoe/interfaces/IJoeRouter02.sol";
import "./StargateAvax.sol";

contract AvaxSwaps is IAvaxSwaps, StargateAvax {

    constructor(IStargateRouter _stargateRouter) StargateAvax(_stargateRouter) {}

    function avaxSwaps(uint8[] calldata steps, bytes[] calldata data) external payable {}

    receive() external payable {}
}