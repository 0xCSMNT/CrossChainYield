// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MockCCIPBnMToken, MockTestToken, MockLinkToken, MockDestinationVault} from "test/dummy-tokens/TestTokens.sol";
import {SourceVault} from "src/SourceVault.sol";
import {ExitVault} from "src/ExitVault.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract DeployContracts is Script {
    MockCCIPBnMToken public mockCCIPBnM;
    MockTestToken public mockTest;
    MockLinkToken public mockLink;
    SourceVault public sourceVault;
    ExitVault public exitVault;
    MockDestinationVault public mockDestinationVault;

    function run() external {
        vm.startBroadcast();

        mockCCIPBnM = new MockCCIPBnMToken();
        mockTest = new MockTestToken();
        mockLink = new MockLinkToken();

        // Deploy SourceVault with required arguments
        sourceVault = new SourceVault(
            ERC20(address(mockCCIPBnM)),
            "ChainlinkVault",
            "CLV",
            address(0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f), // Dummy router address Anvil 8
            address(mockLink) // Dummy Link Token
        );
        exitVault = new ExitVault();
        exitVault.setSourceVault(address(sourceVault));

        mockDestinationVault = new MockDestinationVault(address(mockCCIPBnM));
        mockDestinationVault.setSourceVault(address(sourceVault));

        // set the destination vault address in the source vault
        sourceVault.addMockDestinationVault(address(mockDestinationVault));
                
        vm.stopBroadcast();
    }
}
