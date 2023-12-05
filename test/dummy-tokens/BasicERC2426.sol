// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract BasicERC4626Vault is ERC4626 {
    constructor(ERC20 assetToken) ERC4626(assetToken, "Basic Vault Token", "BVT") {}

    // Deposit function for users to deposit assets into the vault
    function deposit(uint256 amount, address receiver) public override returns (uint256 shares) {
        return super.deposit(amount, receiver);
    }

    // Withdraw function for users to withdraw assets from the vault
    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256 shares) {
        return super.withdraw(assets, receiver, owner);
    }

    // Redeem function for users to redeem shares from the vault
    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256 assets) {
        return super.redeem(shares, receiver, owner);
    }

    // Custom function to show total assets held in the vault
    function totalVaultAssets() public view returns (uint256) {
        return totalAssets();
    }
}