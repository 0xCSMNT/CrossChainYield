// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
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
    

contract MockTokenDeployer {    
    MockCCIPBnMToken public mockCCIPBnM;
    MockTestToken public mockTest;
    MockLinkToken public mockLink;
    
     
    constructor() {
        mockCCIPBnM = new MockCCIPBnMToken();
        mockTest = new MockTestToken();
        mockLink = new MockLinkToken();        
    }
}