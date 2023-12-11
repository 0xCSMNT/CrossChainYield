// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {DestinationVaultV2} from "src/DestinationVault.sol";

import {SourceVault} from "src/SourceVault.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// FUJI TESTNET ADDRESSES
address constant USDT_USD_PRICE_FEED_FUJI = 0x7898AcCC83587C3C55116c5230C17a6Cd9C71bad;
address constant CCIP_BNM_FUJI = 0xD21341536c5cF5EB1bcb58f6723cE26e8D8E90e4;
address constant ROUTER_FUJI = 0x554472a2720E5E7D5D3C817529aBA05EEd5F82D8;
address constant LINK_FUJI = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
uint64 constant CHAIN_ID_SEPOLIA = 16015286601757825753;

// address constant CCIP_BNM_SEPOLIA = 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05;
// address constant ROUTER_SEPOLIA = 0xD0daae2231E9CB96b94C8512223533293C3693Bf;
// address constant LINK_SEPOLIA = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
// uint64 constant CHAIN_ID_FUJI = 14767482510784806043;
// address constant SOURCE_VAULT_FUJI = 0x96C5c9fFC7Eb5EF82873380adF7513FE6EB5a170;

contract DeployContracts is Script {    
    SourceVault public sourceVault; 
    // DestinationVaultV2 public destinationVault;         

    function run() external {
        vm.startBroadcast();        

        // // Deploy SourceVault with required arguments
        sourceVault = new SourceVault(
            address(ROUTER_FUJI),
            address(LINK_FUJI),
            ERC20(address(CCIP_BNM_FUJI)),
            "CCIP Vault",
            "CLV",
            address(USDT_USD_PRICE_FEED_FUJI)             
        );
        sourceVault.allowlistDestinationChain(CHAIN_ID_SEPOLIA, true);
        sourceVault.allowlistSourceChain(CHAIN_ID_SEPOLIA, true);
                

        // Deploy DestinationVaultV2 with required arguments
        // destinationVault = new DestinationVaultV2(
        //     address(ROUTER_SEPOLIA),
        //     address(LINK_SEPOLIA),
        //     SOURCE_VAULT_FUJI,
        //     CHAIN_ID_FUJI            
        // );
        // destinationVault.allowlistDestinationChain(CHAIN_ID_FUJI, true);
        // destinationVault.allowlistSourceChain(CHAIN_ID_FUJI, true);
        // destinationVault.allowlistSender(SOURCE_VAULT_FUJI, true);

        vm.stopBroadcast();
    }
}