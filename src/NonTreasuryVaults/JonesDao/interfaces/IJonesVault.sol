//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IJonesVault {
    function deposit(uint256 _assets, address _receiver)
        external
        returns (uint256 shares);

    function mint(uint256 _shares, address _receiver)
        external
        returns (uint256 assets);

    function withdraw(
        uint256 _assets,
        address _receiver,
        address
    ) external returns (uint256 shares);

    function redeem(
        uint256 _shares,
        address _receiver,
        address
    ) external returns (uint256 assets);
}
