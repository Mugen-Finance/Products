//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * TODO
 * Look at preview mint and preview deposit to see what is happening there
 * Check to ensure withdraws and deposits are handeled correctly
 */

import "openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IETHPool} from "./interfaces/IETHPool.sol";
import {IETHRewards} from "./interfaces/IETHRewards.sol";

contract CapETHVault is ERC4626 {
    IETHPool public immutable ethPool;
    IETHRewards public immutable ethRewards;

    constructor(
        IERC20 asset,
        string memory name,
        string memory symbol,
        address _ethPool,
        address _ethRewards
    ) ERC4626(asset) ERC20(name, symbol) {
        ethPool = IETHPool(_ethPool);
        ethRewards = IETHRewards(_ethRewards);
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(address receiver)
        public
        payable
        virtual
        returns (uint256)
    {
        require(msg.value > 0, "cannot deposit 0 ETH");
        require(
            msg.value <= maxDeposit(receiver),
            "ERC4626: deposit more than max"
        );
        uint256 assets = msg.value;
        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-mint}. */
    function mint(address receiver) public payable virtual returns (uint256) {
        require(msg.value > 0, "cannot deposit 0 ETH");
        require(msg.value <= maxMint(receiver), "ERC4626: mint more than max");
        uint256 shares = msg.value;
        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    function afterDeposit() internal {
        ethPool.deposit{value: balanceOf(address(this))}(msg.value);
    }

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
        _mint(receiver, shares);
        afterDeposit();
        emit Deposit(caller, receiver, assets, shares);
    }

    function beforeWithdraw(uint256 amount) internal {
        ethPool.withdraw(amount);
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
        payable(receiver).transfer(assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function compound() external {
        ethRewards.collectReward();
        ethPool.deposit{value: balanceOf(address(this))}(0);
    }

    receive() external payable {}
}
