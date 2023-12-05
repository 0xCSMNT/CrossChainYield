// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {SourceVault} from "src/SourceVault.sol";
import {MockCCIPBnMToken, MockTestToken} from "test/dummy-tokens/TestTokens.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DeployContracts} from "script/DeployContracts.s.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";

contract ERC4626Test is StdCheats, Test {
    SourceVault public sourceVault;
    MockCCIPBnMToken public mockCCIPBnM;
    MockTestToken public mockTest;

    // CONSTANTS
    uint256 public constant TOKEN_MINT_BALANCE = 100;
    uint256 public constant TOKEN_TRANSFER_AMOUNT = 10;
    address public constant DEV_ACCOUNT_0 =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    // SETUP FUNCTION
    function setUp() external {
        DeployContracts deployer = new DeployContracts();
        deployer.run();

        // Initialize the deployed contracts
        sourceVault = deployer.sourceVault();
        mockCCIPBnM = deployer.mockCCIPBnM();
        mockTest = deployer.mockTest();
    }

    ////////// HELPER FUNCTIONS //////////

    ////////// TEST FUNCTIONS //////////
    function testCorrectAssetAddress() public {
        // Check that the asset address is correct
        assertEq(
            address(sourceVault.asset()),
            address(mockCCIPBnM),
            "Asset address is incorrect"
        );
    }

    // test that user can deposit
    function testDeposit() public {
       vm.startPrank(DEV_ACCOUNT_0);
       sourceVault._deposit(TOKEN_TRANSFER_AMOUNT);
       vm.stopPrank();
       //assert total assets are equal to the amount deposited
       assertEq(sourceVault.totalAssets(), TOKEN_TRANSFER_AMOUNT, "Total assets are not equal to the amount deposited");
    }
}
