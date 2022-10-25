//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {ERC4626, ERC20} from "solmate/src/mixins/ERC4626.sol";
import {CapPositionHandler} from "./CapPositionHandler.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {WETH} from "solmate/src/tokens/WETH.sol";

/**
 * Design Notes:
 * The purpose of this contract is to create a close to delta neutral vault using cap finance. Allowing users to take
 * ETH deposits and passing the, into the LP vault for cap, and opening a short position at the same time
 * Earned rewards will be compounded and at the time of the compound the vault will also rebalance the positions. Ensuring that the position is delta neutral.
 *
 * Design considerations:
 * Handling deposits at different times, handling rebalances, handling withdraws and proper asset accounting.
 * Opening and closing shorts
 *
 * Handle ETH deposits
 * Deposit / Withdraw opening and closing
 */

contract CapFinanceDeltaVault is ERC4626, CapPositionHandler {
    using SafeTransferLib for ERC20;
    address private keeper;

    WETH public immutable weth;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        address _rewards,
        address _ethPool,
        address _trading,
        WETH _weth
    )
        ERC4626(_asset, _name, _symbol)
        CapPositionHandler(_rewards, _ethPool, _trading)
    {
        weth = _weth;
    }

    function totalAssets() public view virtual override returns (uint256) {
        //pass
    }

    function deposit(uint256 assets, address receiver)
        public
        virtual
        override
        returns (uint256 shares)
    {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function mint(uint256 shares, address receiver)
        public
        virtual
        override
        returns (uint256 assets)
    {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
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
    {
        weth.withdraw(asset.balanceOf(address(this)));
    }

    function rebalance() external onlyKeeper {
        _rebalance();
    }

    modifier onlyKeeper() {
        if (msg.sender != keeper) revert NotKeeper();
        _;
    }

    receive() external payable {
        deposit(msg.value, msg.sender);
    }
}
