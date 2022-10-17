// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/mocks/MockstMugen.sol";
import "../src/mocks/MockStaking.sol";
import "../src/mocks/MockERC20.sol";
import "../src/interfaces/IStake.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

//Mocks do not have the oracle and pool set up, that has to be done on testnet or with forking

contract MockCompounder is Test {
    MockstMugen stMGN;
    MockStaking stake;
    MockERC20 mgn;

    function setUp() public {
        mgn = new MockERC20("Mugen", "MGN", address(this), type(uint256).max);
        stake = new MockStaking(address(mgn), address(mgn));
        stMGN = new MockstMugen(
            IERC20(mgn),
            "Staked Mugen",
            "stMGN",
            address(stake)
        );

        stake.setYield(address(this));
        mgn.approve(address(stMGN), type(uint256).max);
        mgn.approve(address(stake), type(uint256).max);
    }

    function testSTMGNDeposits(uint256 x) public {
        vm.assume(x > 0);
        stMGN.deposit(x, address(this));
        assertEq(stMGN.balanceOf(address(this)), x);
        assertEq(stMGN.totalSupply(), x);
        assertEq(stMGN.totalAssets(), x);
    }

    function testSTMGNMints(uint256 x) public {
        vm.assume(x > 0);
        uint256 minted = stMGN.mint(x, address(this));
        assertEq(stMGN.balanceOf(address(this)), minted);
        assertEq(stMGN.totalSupply(), minted);
        assertEq(stMGN.totalAssets(), minted);
    }

    function testSTMGNAccounting(uint256 x) public {
        vm.assume(x > 0 && x < 1e40);
        stMGN.deposit(x, address(this));
        assertEq(stake.balanceOf(address(stMGN)), x);
        stake.issuanceRate(100000 * 1e18);
        vm.warp(20 days);
        stMGN.compoundMGN();
        assertGt(stMGN.totalAssets(), x);
    }

    //Logic is different from mainnet contracts, but represents a similar action on the backend
    function testCompoundThenReedem(uint256 x) public {
        vm.assume(x > 2);
        vm.assume(x < 1e30);
        stMGN.deposit(x, address(this));
        uint256 shares = stMGN.balanceOf(address(this));
        assertEq(stake.balanceOf(address(stMGN)), x);
        stake.issuanceRate(100000 * 1e18);
        vm.warp(25 days);
        stMGN.compoundMGN();
        uint256 redeemed = stMGN.redeem(shares, address(this), address(this));
        assertEq(stMGN.totalSupply(), 0);
        assertEq(stMGN.totalAssets(), 0);
        assertGt(redeemed, shares);
    }
}
