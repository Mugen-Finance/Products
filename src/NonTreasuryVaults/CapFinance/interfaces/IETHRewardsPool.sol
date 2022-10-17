// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IETHRewardsPool {
    function collectReward() external;

    function getClaimableReward() external view returns (uint256);
}
