// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MockCCIPBnMToken, MockTestToken} from "test/dummy-tokens/TestTokens.sol";
import {SourceVault} from "src/SourceVault.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract DeployContracts is Script {
    MockCCIPBnMToken public mockCCIPBnM;
    MockTestToken public mockTest;
    SourceVault public sourceVault;

    function run() external {
        vm.startBroadcast();

        mockCCIPBnM = new MockCCIPBnMToken();
        mockTest = new MockTestToken();

        // Deploy SourceVault with required arguments
        sourceVault = new SourceVault(
            ERC20(address(mockCCIPBnM)),
            "ChainlinkVault",
            "CLV",
            address(0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f), // Dummy router address Anvil 8
            address(0xa0Ee7A142d267C1f36714E4a8F75612F20a79720) // Dummy link token address Anvil 9
        );
    }
}
