// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";

contract ExitVault is OwnerIsCreator {
    // STRUCTS

    // STATE VARIABLES
    IRouterClient public router;
    LinkTokenInterface linkToken;
    address public sourceVault;
    address public destinationVault;

    mapping(uint64 => bool) public whitelistedChains;
    mapping(address => uint256) public withdrawalLimit;

    // EVENTS
    event TokenReceivedFromBridge(address indexed token, uint256 amount);
    event TokenWithdrawanByCustomer(uint256 amount);

    // MODIFIERS
    modifier onlyWhitelistedChains(uint64 _chainId) {
        require(whitelistedChains[_chainId], "Chain not whitelisted");
        _;
    }

    modifier onlyDestinationVault() {
        require(
            msg.sender == destinationVault,
            "Only the destination vault can call this function"
        );
        _;
    }

    // FUNCTIONS

    // Set a customer withdrawal limit so they can withdraw funds
    function increaseWithdrawalLimit(address customer, uint256 limitIncrease) external onlyDestinationVault {
        withdrawalLimit[customer] += limitIncrease;
    }

    // have an executeWithdrawal() function that can be call by customer
        // should set withdraw limit back to zero for that address
    
    // Set the source vault address
    function setSourceVault(address _sourceVault) external onlyOwner {
        sourceVault = _sourceVault;
    }
    
    // Set the destination vault address
    function setDestinationVault(address _destinationVault) external onlyOwner {
        destinationVault = _destinationVault;
    }
    
    // whitelist chains
    function whitelistChain(uint64 _chainId) external onlyOwner {
        whitelistedChains[_chainId] = true;
    }
        
}