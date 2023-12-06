// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "lib/solmate/src/utils/FixedPointMathLib.sol";

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";
import {ERC4626} from "lib/solmate/src/mixins/ERC4626.sol";

// TODO: CREATE PROPER CONTRACT DESCRIPTION

contract SourceVault is ERC4626, OwnerIsCreator {
    
    // STRUCTS
    
    // STATE VARIABLES
    IRouterClient public router;
    LinkTokenInterface linkToken;
    address public destinationVault;
    address public exitVault;
    
    mapping(uint64 => bool) public whitelistedChains;
    mapping(address => uint256) public shareHolder;

    // EVENTS
    event TokenBridged(address indexed token, uint256 amount);
    event AccountingUpdated(uint256 totalAssets);

    // MODIFIERS
    modifier onlyWhitelistedChains(uint64 _chainId) { 
        require(whitelistedChains[_chainId], "Chain not whitelisted");
        _;
     }
    
    // TODO: Implement these modifiers
    // modifier onlyDestinationVault() { ... }
    // modifier onlyExitVault() { ... }

    // CONSTRUCTOR
    constructor(ERC20 _asset, string memory _name, string memory _symbol, address _router, address _link)
        ERC4626(_asset, _name, _symbol)
        OwnerIsCreator()
    {
        router = IRouterClient(_router);
        linkToken = LinkTokenInterface(_link);
    }

    // ERC4626 FUNCTIONS
    
    // Deposit assets into the vault and mint shares to the user
    function _deposit(uint _assets) public {
        require(_assets > 0, "Deposit must be greater than 0");
        deposit(_assets, msg.sender);
        shareHolder[msg.sender] += _assets; // mints an equal amount of shares to the number of assets deposited
    }

    function _withdraw(uint _shares, address _receiver) public {
        
        // Implementation details
    }
 
    function totalAssets() public view override returns (uint256) {
    return asset.balanceOf(address(this));
    }

    function totalAssetsOfUser(address _user) public view returns (uint256) {
    return asset.balanceOf(_user);
    }

    function whitelistChain(uint64 _chainId) public onlyOwner {
        whitelistedChains[_chainId] = true;
    }

    function denylistChain(uint64 _chainId) public onlyOwner {
        whitelistedChains[_chainId] = false;
    }

    function addExitVault(address _exitVault) public onlyOwner {
        exitVault = _exitVault;
    }

    function addDestinationVault(address _destinationVault) public onlyOwner {
        destinationVault = _destinationVault;
    }
    
    // CCIP MESSAGE FUNCTIONS
    function transferTokensToDestinationVault(uint64 _destinationChainSelector, address _receiver, address _token, uint256 _amount) public {
        // Token transfer implementation
    }

    function requestWithdrawalFromDestinationVault(uint64 _destinationChainSelector, address _receiver, address _token, uint256 _amount) public {
        // Withdrawal request implementation
    }

    function _ccipReceive(bytes memory _message) internal {
        // CCIP receive implementation
    }

    // RESTRICTED ACCESS FUNCTIONS
    function exitAndUpdate() external /* TODO onlyExitVault */ {
        // ExitVault update logic
    }

    function lockVault() internal {
        // Vault locking logic
    }

    function unlockVault() external /* TODO: onlyDestinationVault */ {
        // Vault unlocking logic
    }
}