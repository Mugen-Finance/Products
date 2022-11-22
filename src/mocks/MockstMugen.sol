//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStake.sol";
import "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//Make Mock Staking contract

contract MockstMugen is ERC4626 {
    using SafeERC20 for IERC20;

    event Staked(uint256 stakedAmount);

    IStake public stake;

    constructor(IERC20 asset, string memory name, string memory symbol, address _stake)
        ERC4626(asset)
        ERC20(name, symbol)
    {
        stake = IStake(_stake);
    }

    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this)) + stake.balanceOf(address(this));
    }

    function afterDeposit(uint256 amount) internal {
        _asset.safeIncreaseAllowance(address(stake), amount);
        stake.stake(amount);
        emit Staked(amount);
    }

    function beforeWithdraw(uint256 _unstakeAmount) internal {
        stake.withdraw(_unstakeAmount);
    }

    function compoundMGN() public {
        stake.getReward();
        uint256 balance = _asset.balanceOf(address(this));
        _asset.safeIncreaseAllowance(address(stake), balance);
        stake.stake(balance);
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual override {
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);
        afterDeposit(assets);
        emit Deposit(caller, receiver, assets, shares);
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        virtual
        override
    {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }
        beforeWithdraw(assets);
        _burn(owner, shares);
        SafeERC20.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }
}
