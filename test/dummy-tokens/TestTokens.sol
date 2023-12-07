// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";
import {IMockDestinationVault} from "interfaces/IMockDestinationVault.sol";
// import "node_modules/@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract MockCCIPBnMToken is ERC20 {
    constructor() ERC20("Mock CCIP-BnM", "mCCIP-BnM", 18) {
        _mint(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 100); // Anvil 0
    }
}

contract MockTestToken is ERC20 {
    constructor() ERC20("TestToken", "TEST", 18) {
        _mint(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 100); // Anvil 0
    }
}

contract MockLinkToken is ERC20 {
    constructor() ERC20("Mock Link", "mLINK", 18) {
        _mint(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 100); // Anvil 0
    }
}

contract MockDestinationVault is IMockDestinationVault {
    IERC20 public mockCCIPBnM;
    IERC20 public mockTestToken;

    uint256 public balanceInMockTestToken;

    // Address of the SourceVault contract
    address public sourceVault;

    constructor(address _mockCCIPBnM, address _mockTestToken) {
        mockCCIPBnM = IERC20(_mockCCIPBnM);
        mockTestToken = IERC20(_mockTestToken);        
    }
    // Function to set the source vault address
    function setSourceVault(address _sourceVault) external {
        // You can add access control here if needed, e.g., onlyOwner
        sourceVault = _sourceVault;
    }

    function getExchangeRate() internal pure returns (uint256) {
        // Represents 0.95 in fixed-point arithmetic with 18 decimal places
        return 950000000000000000;
    }

    function swapAndAppendBalance(uint256 mockCCIPBnMAmount) external {
        // Ensure that the caller is the SourceVault
        require(msg.sender == sourceVault, "Caller is not SourceVault");

        // Calculate the equivalent amount in MockTestToken
        uint256 equivalentMockTestTokenAmount = mockCCIPBnMAmount * getExchangeRate() / 1e18;

        // Simulate the swap by updating the balance
        balanceInMockTestToken += equivalentMockTestTokenAmount;

        // Simulate sending a message back to the SourceVault to update its balance
        // Assuming SourceVault has a function called 'updateBalanceFromDestination'
        // (address(this), balanceInMockTestToken) would be the parameters in a real call
        // SourceVault(sourceVault).updateBalanceFromDestination(address(this), balanceInMockTestToken);
    }
}

   

contract MockTokenDeployer {    
    MockCCIPBnMToken public mockCCIPBnM;
    MockTestToken public mockTest;
    MockLinkToken public mockLink;
    MockDestinationVault public mockDestinationVault;
    
     
    constructor() {
        mockCCIPBnM = new MockCCIPBnMToken();
        mockTest = new MockTestToken();
        mockLink = new MockLinkToken();  
        mockDestinationVault = new MockDestinationVault(address(mockCCIPBnM), address(mockTest));      
    }
}