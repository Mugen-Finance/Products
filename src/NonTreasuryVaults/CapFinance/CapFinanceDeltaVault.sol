//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {ERC4626} from "solmate/src/mixins/ERC4626.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {CapPositionHandler} from "./CapPositionHandler.sol";

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

contract CapFinanceDeltaVault is ERC4626, CapPositionHandler {
    address private keeper;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        address _rewards,
        address _ethPool
    ) ERC4626(_asset, _name, _symbol) CapPositionHandler(_rewards, _ethPool) {}

    function totalAssets() public view virtual override returns (uint256) {
        //pass
    }

    function beforeWithdraw(uint256 assets, uint256 shares)
        internal
        virtual
        override
    {}

    function afterDeposit(uint256 assets, uint256 shares)
        internal
        virtual
        override
    {}

    function rebalance() external onlyKeeper {
        _rebalance();
    }

    modifier onlyKeeper() {
        if (msg.sender != keeper) revert NotKeeper();
        _;
    }
}
