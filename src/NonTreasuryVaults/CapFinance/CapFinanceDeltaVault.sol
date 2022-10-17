//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {ERC4626, ERC20} from "openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * Design Notes:
 * The purpose of this contract is to create a close to delta neutral vault using cap finance. Allowing users to take
 * ETH deposits and passing the, into the LP vault for cap, and opening a short position at the same time
 * Earned rewards will be compounded and at the time of the compound the vault will also rebalance the positions. Ensuring that the position is delta neutral.
 *
 * Design considerations:
 * Handling deposits at different times, handling rebalances, handling withdraws and proper asset accounting.
 * Opening and closing shorts
 */

contract CapFinanceDeltaVault is ERC4626 {
    constructor(
        IERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC4626(_asset) ERC20(_name, _symbol) {}
}
