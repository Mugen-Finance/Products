//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IStake {
    function compound(uint256 amountOutMin) external;

    function stake(uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function withdraw(uint256 amount) external;

    function earned(address account) external view returns (uint256);

    function getReward() external returns (uint256);
}
