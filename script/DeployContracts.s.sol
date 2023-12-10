// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MockDestinationVault} from "test/dummy-tokens/TestTokens.sol";
import {SourceVault} from "src/SourceVault.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// FUJI TESTNET ADDRESSES
address constant USDT_USD_PRICE_FEED_FUJI = 0x7898AcCC83587C3C55116c5230C17a6Cd9C71bad;
address constant CCIP_BNM_FUJI = 0xD21341536c5cF5EB1bcb58f6723cE26e8D8E90e4;
address constant ROUTER_FUJI = 0x554472a2720E5E7D5D3C817529aBA05EEd5F82D8;
address constant LINK_FUJI = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;

contract DeployContracts is Script {    
    SourceVault public sourceVault;        

    function run() external {
        vm.startBroadcast();        

        // Deploy SourceVault with required arguments
        sourceVault = new SourceVault(
            ERC20(address(CCIP_BNM_FUJI)),
            "ChainlinkVault",
            "CLV",
            address(ROUTER_FUJI), 
            address(LINK_FUJI), 
            address(USDT_USD_PRICE_FEED_FUJI) // Passing the price feed address
        );   
        
        vm.stopBroadcast();
    }
}