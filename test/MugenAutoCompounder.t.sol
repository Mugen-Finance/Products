// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/MugenAutoCompounder.sol";
import "../src/mocks/MockERC20.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MugenAutoCompounderTest is Test {
    MugenAutoCompounder mac;
    address mugenWhale = address(0xCe3dC36Cd501C00f643a09f2C8d9b69Fb941bB74);
    address factory = address(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    function setUp() public {
        mac = new MugenAutoCompounder(
            IERC20(0xFc77b86F3ADe71793E1EEc1E7944DB074922856e),
            "stMugen",
            "stMGN",
            factory,
            10000
        );
    }

    function testOracle() public returns (uint256 price) {
        uint256 amount = IERC20(0xFc77b86F3ADe71793E1EEc1E7944DB074922856e)
            .balanceOf(mugenWhale);
        vm.prank(mugenWhale);
        IERC20(0xFc77b86F3ADe71793E1EEc1E7944DB074922856e).transfer(
            address(this),
            amount / 2
        );
        IERC20(0xFc77b86F3ADe71793E1EEc1E7944DB074922856e).approve(
            address(mac),
            type(uint256).max
        );
        mac.deposit(amount / 3, address(this));
        price = mac.estimateAmoutOut();
    }

    function transferAndApprove() public {
        uint256 amount = IERC20(0xFc77b86F3ADe71793E1EEc1E7944DB074922856e)
            .balanceOf(mugenWhale);
        vm.prank(mugenWhale);
        IERC20(0xFc77b86F3ADe71793E1EEc1E7944DB074922856e).transfer(
            address(this),
            amount / 2
        );
        IERC20(0xFc77b86F3ADe71793E1EEc1E7944DB074922856e).approve(
            address(mac),
            type(uint256).max
        );
    }

    function testMACDeposit() public {
        transferAndApprove();
        mac.deposit(100 * 1e18, address(this));
        assertEq(mac.balanceOf(address(this)), 100 * 1e18);
        assertEq(mac.totalSupply(), 100 * 1e18);
    }

    function testMACWithdraw() public {
        testMACDeposit();
        mac.withdraw(100 * 1e18, address(this), address(this));
    }
}
