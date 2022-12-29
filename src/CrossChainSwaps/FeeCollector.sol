//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

contract FeeCollector is Ownable {
    using SafeERC20 for IERC20;
    using SafeTransferLib for *;

    error TransactionFailed();

    constructor() {}

    function withdraw(IERC20 _token) external onlyOwner {
        _token.safeTransfer(owner(), _token.balanceOf(address(this)));
    }

    function withdrawNative() external onlyOwner {
        address owner = owner();
        uint256 amount = address(this).balance;
        owner.safeTransferETH(amount);
    }

    receive() external payable {}
}
