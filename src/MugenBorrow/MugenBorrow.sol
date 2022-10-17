//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * Users need to be able to withdraw there funds plus interest, and liquidity mining rewards (Liquidity mining rewards will have to be a seperate contract) (Currently set up as a fixed rate with no utlization curve)
 * Look into ways to fix that so that one there is a utlization curve, and two it is implemented into the calculations of this.
 * There needs to be a way to calculate the interest rate
 * Create a pool factory
 * Probably will need a strategy controller factory as well so that individuals can pick and choice which strategies they want
 * Wrapper for Tokens minted through the pools
 * Management fee for other pools created
 */

import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC4626, ERC20} from "openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IStrategyController} from "./interfaces/IStrategyController.sol";
import {Pausable} from "openzeppelin/contracts/security/Pausable.sol";

contract MugenBorrow is ERC4626, Pausable {
    using SafeERC20 for IERC20;

    uint256 private assetsDeposited;
    IStrategyController public strategy;
    uint256 public interest; //The interest that has been accumulated thus far
    uint256 public constant rate = 500;
    uint256 private lastCalculated; //Most recent timestamp that calculated interest.

    constructor(
        IERC20 asset,
        string memory name,
        string memory symbol
    ) ERC4626(asset) ERC20(name, symbol) {}

    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this)) + assetsDeposited;
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(uint256 assets, address receiver)
        public
        virtual
        override
        updateAccumulatedInterest
        whenNotPaused
        returns (uint256)
    {
        require(
            assets <= maxDeposit(receiver),
            "ERC4626: deposit more than max"
        );

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-mint}. */
    function mint(uint256 shares, address receiver)
        public
        virtual
        override
        updateAccumulatedInterest
        whenNotPaused
        returns (uint256)
    {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        // If _asset is ERC777, `transferFrom` can trigger a reenterancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        afterDeposit(assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    function afterDeposit(uint256 _assetsDeposited) internal {
        assetsDeposited += _assetsDeposited;
        _asset.safeTransfer(address(strategy), _assetsDeposited);
    }

    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        beforeWithdraw(assets);
        _burn(owner, shares);
        SafeERC20.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function beforeWithdraw(uint256 _assetsWithdrawn) internal {
        if (_assetsWithdrawn <= _asset.balanceOf(address(this))) {
            assetsDeposited -= _assetsWithdrawn;
        } else {
            assetsDeposited -= _assetsWithdrawn;
            strategy.withdraw(_assetsWithdrawn);
        }
    }

    function totalDeposits() internal view returns (uint256 _assetsDeposited) {
        return assetsDeposited;
    }

    function repayInterest(uint256 amount) external {
        require(msg.sender == address(strategy));
        interest -= amount;
        _asset.safeTransferFrom(address(strategy), address(this), amount);
    }

    function repayLoan(uint256 amount) external {
        require(
            amount >=
                (assetsDeposited + interest - _asset.balanceOf(address(this)))
        );
        require(msg.sender == address(strategy));
        _pause();
        _asset.safeTransferFrom(address(strategy), address(this), amount);
    }

    function updateInterest() internal {
        if (paused()) {
            interest = 0;
        } else {
            interest +=
                (totalDeposits() * rate * (block.timestamp - lastCalculated)) /
                10000;
            lastCalculated = block.timestamp;
        }
    }

    modifier updateAccumulatedInterest() {
        updateInterest();
        _;
    }
}
