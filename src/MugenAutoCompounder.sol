//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IStake.sol";
import "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

contract MugenAutoCompounder is ERC4626 {
    using SafeERC20 for IERC20;

    //setUp for testnet, make sure to change prior to mainnet.
    address public constant MGN = 0xFc77b86F3ADe71793E1EEc1E7944DB074922856e;
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    IStake public constant stake =
        IStake(0x25B9f82D1F1549F97b86bd0873738E30f23D15ea);

    address public immutable pool;

    event Staked(uint256 stakedAmount);

    constructor(
        IERC20 asset,
        string memory name,
        string memory symbol,
        address _factory,
        uint24 _fee
    ) ERC4626(asset) ERC20(name, symbol) {
        address _pool = IUniswapV3Factory(_factory).getPool(MGN, WETH, _fee);
        require(_pool != address(0), "Pool does not exist");
        pool = _pool;
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
        uint256 amount = (uint256(estimateAmoutOut()) * 9900) / 10000;
        stake.compound(amount);
    }

    //oracle functions
    function estimateAmoutOut() public view returns (uint256 amountOut) {
        uint128 amountIn = uint128(stake.earned(address(this)));
        (int24 tick, ) = OracleLibrary.consult(pool, 180 seconds);
        amountOut = OracleLibrary.getQuoteAtTick(tick, amountIn, WETH, MGN);
    }

    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);
        afterDeposit(assets);
        emit Deposit(caller, receiver, assets, shares);
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
        beforeWithdraw(assets);
        _burn(owner, shares);
        SafeERC20.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }
}
