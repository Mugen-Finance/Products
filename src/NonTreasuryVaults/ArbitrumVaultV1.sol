//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {ERC4626, ERC20} from "openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * Have a basket of yield sources on arbitrum that allow for users to gain yield on USDC.
 * What strategies should be implemented
 *  GLP, Ribbon lend, ribbon earn,
 * Can use the vesta finance oracle
 * How many
 * How often is yield collected or compounded?
 * How to handle withdrawals?
 * the additional functionality will just be called by the keepers to send to the contract. Just need to add in the call for
 * withdraw in order to the withdraw order to the correct contract. So will need to build out the strategy first at a seperate contract.
 */

/**
 * TODO
 * Fix Total Assets to account for deployed funds
 * Withdraw will
 */

contract ArbitrumVaultV1 is ERC4626 {
    using SafeERC20 for IERC20;

    constructor(
        IERC20 asset,
        string memory name_,
        string memory symbol_,
        address _arbitrumVaultStrategyV1
    ) ERC4626(asset) ERC20(name_, symbol_) {
        arbitrumVaultStrategyV1 = _arbitrumVaultStrategyV1;
    }

    // ///@notice address for the strategy contract
    address private immutable arbitrumVaultStrategyV1;
    // mapping(address => uint256) public timelock; //After each deposit there is a 1 day lockup period where you are not able to withdraw.
    // ///@notice sends the funds to the strategy contract
    // function deploy() external {
    //     uint256 balance = IERC20(_asset).balanceOf(address(this));
    //     IERC20(_asset).safeTransfer(arbitrumVaultStrategyV1, balance);
    // }
    // function deposit(uint256 assets, address receiver)
    //     public
    //     virtual
    //     override
    //     returns (uint256)
    // {
    //     require(
    //         assets <= maxDeposit(receiver),
    //         "ERC4626: deposit more than max"
    //     );
    //     _totalAssets += assets;
    //     timelock[msg.sender] += 1 days;
    //     uint256 shares = previewDeposit(assets);
    //     _deposit(_msgSender(), receiver, assets, shares);
    //     return shares;
    // }
    // /** @dev See {IERC4626-mint}. */
    // function mint(uint256 shares, address receiver)
    //     public
    //     virtual
    //     override
    //     returns (uint256)
    // {
    //     require(shares <= maxMint(receiver), "ERC4626: mint more than max");
    //     timelock[msg.sender] += 1 days;
    //     uint256 assets = previewMint(shares);
    //     _totalAssets += assets;
    //     _deposit(_msgSender(), receiver, assets, shares);
    //     return assets;
    // }
    // function withdraw(
    //     uint256 assets,
    //     address receiver,
    //     address owner
    // ) public virtual override returns (uint256) {
    //     require(
    //         assets <= maxWithdraw(owner),
    //         "ERC4626: withdraw more than max"
    //     );
    //     uint256 shares = previewWithdraw(assets);
    //     _totalAssets -= assets;
    //     _withdraw(_msgSender(), receiver, owner, assets, shares);
    //     return shares;
    // }
    // /** @dev See {IERC4626-redeem}. */
    // function redeem(
    //     uint256 shares,
    //     address receiver,
    //     address owner
    // ) public virtual override returns (uint256) {
    //     require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");
    //     uint256 assets = previewRedeem(shares);
    //     _totalAssets -= assets;
    //     _withdraw(_msgSender(), receiver, owner, assets, shares);
    //     return assets;
    // }
}
