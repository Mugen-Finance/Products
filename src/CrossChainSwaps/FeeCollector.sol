//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FeeCollector is Ownable {
    using SafeERC20 for IERC20;

    error TransactionFailed();

    constructor() {}

    function withdraw(IERC20 _token) external onlyOwner {
        _token.safeTransfer(owner(), _token.balanceOf(address(this)));
    }

    function withdrawNative() external onlyOwner {
        address owner = owner();
        uint256 amount = address(this).balance;
        (bool success, ) = owner.call{value: amount}("");
        if(!success) revert TransactionFailed();

    }

    receive() external payable {}
}