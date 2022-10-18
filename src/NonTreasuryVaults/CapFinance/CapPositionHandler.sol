//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

//Contract that handles LP deposits and the opening and closing of positions for cap finance shorts
import {ITrading} from "./interfaces/ITrading.sol";
import {IETHRewardsPool} from "./interfaces/IETHRewardsPool.sol";
import {IETHPool} from "./interfaces/IETHPool.sol";

abstract contract CapPositionHandler {
    error NotKeeper();

    IETHRewardsPool public immutable rewards;
    IETHPool public immutable ethPool;

    constructor(address _rewards, address _ethPool) {
        rewards = IETHRewardsPool(_rewards);
        ethPool = IETHPool(_ethPool);
    }

    function openPosition() internal {}

    function closePosition() internal {}

    function provideLp() external payable {
        ethPool.deposit{value: msg.value}(0);
    }

    function _rebalance() internal {}

    function collectRewards() internal {
        rewards.collectReward();
    }

    function withdraw() internal {}
}
