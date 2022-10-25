//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

//Contract that handles LP deposits and the opening and closing of positions for cap finance shorts
// Handling fees
import {ITrading} from "./interfaces/ITrading.sol";
import {IETHRewardsPool} from "./interfaces/IETHRewardsPool.sol";
import {IETHPool} from "./interfaces/IETHPool.sol";

abstract contract CapPositionHandler {
    error NotKeeper();
    bytes32 internal constant productId =
        0x4554482d55534400000000000000000000000000000000000000000000000000;

    IETHRewardsPool public immutable rewards;
    IETHPool public immutable ethPool;
    ITrading public immutable trading;

    uint256 private currentPositionSize;

    enum State {
        Deposit,
        InPosition,
        Withdraw
    }

    constructor(
        address _rewards,
        address _ethPool,
        address _trading
    ) {
        rewards = IETHRewardsPool(_rewards);
        ethPool = IETHPool(_ethPool);
        trading = ITrading(_trading);
    }

    function openPosition(uint256 amount) internal {
        currentPositionSize += amount;
        trading.submitOrder(productId, address(0), false, amount, amount);
    }

    function closePosition() internal {
        uint256 fee = (currentPositionSize * 10) / 10000;
        trading.submitCloseOrder{value: fee}(
            productId,
            address(0),
            false,
            currentPositionSize
        );
        currentPositionSize = 0;
    }

    function provideLp(uint256 amount) internal {
        ethPool.deposit{value: amount}(0);
    }

    function _rebalance() internal {
        uint256 amount = address(this).balance;
        uint256 half = amount / 2;
        openPosition(half);
        provideLp(half);
    }

    function collectRewards() internal {
        rewards.collectReward();
    }

    function withdraw() internal {}
}

/**
 * Submit an order
Scroll down to submitOrder and enter:
payableAmount is your margin if submitting an ETH based trade. Enter the amount in wei (18 decimals). For ERC20 based trades, leave this blank and enter the amount in the margin field.
productId.
currency.
isLong. Enter 1 to go long, 0 to go short.
margin. In base units.
size. In base units. Size / margin determines your position's leverage.
Cancel an order
If your order has not yet been executed by the oracle, you can cancel it. Scroll down to cancelOrder and enter:
productId. Your order's productId.
currency. Your order's currency.
isLong. Your order's direction (1 for long, 0 for short).
Close a position
Scroll down to submitCloseOrder and enter:
payableAmount is the fee to pay if submitting an ETH based trade. Enter the amount in wei (18 decimals), usually 0.1% * your trade size. Otherwise leave blank.
productId. Your position's productId.
currency. Your position's currency.
isLong. Your position's direction.
size. In base units. The amount you want to close.
 */
