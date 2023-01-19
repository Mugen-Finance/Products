//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/CrossChainSwaps/FeeCollector.sol";
import "../src/mocks/MockERC20.sol";

contract FeeCollectorTest is Test {
    FeeCollector feeCollector;
    MockERC20 mock;

    function setUp() public {
        feeCollector = new FeeCollector();
        mock = new MockERC20("Test", "TTK", address(this), 1e40);
    }

    function testEthWithdraw(address addr) public {
        (bool success,) = address(feeCollector).call{value: 10 ether}("");
        success;
        vm.assume(addr != address(this) && addr != address(0));

        vm.prank(addr);
        vm.expectRevert();
        feeCollector.withdrawNative();
        assertEq(address(feeCollector).balance, 10 ether);

        uint256 balanceBefore = address(this).balance;
        feeCollector.withdrawNative();
        assertEq(address(feeCollector).balance, 0);
        assertEq(address(this).balance, balanceBefore + 10 ether);
    }

    function testERC20Withdraw(address addr) public {
        IERC20(mock).transfer(address(feeCollector), 1e30);
        vm.assume(addr != address(this) && addr != address(0));

        vm.prank(addr);
        vm.expectRevert();
        feeCollector.withdraw(mock);
        assertEq(IERC20(mock).balanceOf(address(feeCollector)), 1e30);

        feeCollector.withdraw(mock);
        assertEq(IERC20(mock).balanceOf(address(feeCollector)), 0);
        assertEq(IERC20(mock).balanceOf(address(this)), 1e40);
        assertEq(feeCollector.owner(), address(this));
    }

    receive() external payable {}
}
