// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";
import {IMockDestinationVault} from "interfaces/IMockDestinationVault.sol";
import {ISourceVault} from "interfaces/ISourceVault.sol";

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
    uint256 public fakeBalance;

    // Address of the SourceVault contract
    address public sourceVault;

    constructor(address _mockCCIPBnM) {
        mockCCIPBnM = IERC20(_mockCCIPBnM);                
    }
 
    // This function is on MockDestinationVault and 
    // updates fakeBalance based on exchange rate and amount of tokens received
    // but no token swaps actually take place
    function swapAndAppendBalance(uint256 mockCCIPBnMAmount) external {
        // checks caller is sourceVault - maybe delete and use a modifier later but this is fine for tesing
        require(msg.sender == sourceVault, "Caller is not SourceVault");         
        
        uint256 balanceUpdate = mockCCIPBnMAmount * getExchangeRate() / 1e18;
        fakeBalance += balanceUpdate;
        
        // Call SourceVault to update the balance
        ISourceVault(sourceVault).updateBalanceFromMockDestinationVault(fakeBalance);   
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
        mockDestinationVault = new MockDestinationVault(address(mockCCIPBnM));      
    }
}