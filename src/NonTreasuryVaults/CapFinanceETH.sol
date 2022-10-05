//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {ERC4626, ERC20} from "openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CapFinanceETH is ERC4626 {
    constructor(
        IERC20 asset,
        string memory name,
        string memory symbol
    ) ERC4626(asset) ERC20(name, symbol) {}

    receive() external payable {}
}
