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

import {IMockDestinationVault} from "interfaces/IMockDestinationVault.sol";
import {ISourceVault} from "interfaces/ISourceVault.sol";

// TODO: CREATE PROPER CONTRACT DESCRIPTION

contract SourceVault is ERC4626, OwnerIsCreator, ISourceVault {
    
    // STRUCTS
    
    // STATE VARIABLES
    IRouterClient public router;
    LinkTokenInterface linkToken;
    address public destinationVault;
    address public exitVault;
    bool public vaultLocked;
    uint256 public DestinationVaultBalance;

    // Mock Variables - delete before deployment
    IMockDestinationVault public mockDestinationVault;
    address public mockDestinationVaultAddress;
    uint256 public mockDestinationVaultBalance;
    
    mapping(uint64 => bool) public whitelistedChains;

    // ERRORS
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); 
    error DestinationChainNotWhitelisted(uint64 destinationChainSelector);
    error NothingToWithdraw();    

    // EVENTS
    event TokensTransferred(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        address token, // The token address that was transferred.
        uint256 tokenAmount, // The token amount that was transferred.
        address feeToken, // the token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the message.
    );
    event AccountingUpdated(uint256 totalAssets);
    event TEST_TokensTransferredToDestinationVault(uint256 amount);
    event FunctionCalledBy(address caller);
    event MockBalanceUpdated(uint256 newBalance);


    // MODIFIERS
    modifier onlyWhitelistedChains(uint64 _chainId) { 
        require(whitelistedChains[_chainId], "Chain not whitelisted");
        _;
     }
    
    modifier onlyDestinationVault(address _destinationVault) {
        require(msg.sender == _destinationVault, "Caller is not DestinationVault");
        _;
    }

    modifier onlyExitVault(address _exitVault) {
        require(msg.sender == _exitVault, "Caller is not ExitVault");
        _;
    }

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
        require(!vaultLocked, "Vault is locked");
        require(_assets > 0, "Deposit must be greater than 0");
        deposit(_assets, msg.sender);        
    }

    function _withdraw(uint _shares, address _receiver) public {
        require(!vaultLocked, "Vault is locked");
        require(_shares > 0, "No funds to withdraw");

        // Convert shares to the equivalent amount of assets
        uint256 assets = previewRedeem(_shares);

        // Withdraw the assets to the receiver's address
        withdraw(assets, _receiver, msg.sender);
    }
    

    function totalAssets() public view override returns (uint256) {  
        uint256 _depositAssetBalance = asset.balanceOf(address(this));
        uint256 _destinationVaultBalance = FixedPointMathLib.mulDivUp(mockDestinationVaultBalance, 1e18, getExchangeRate());
        uint256 _totalAssets = _depositAssetBalance + _destinationVaultBalance;
        return _totalAssets;              
    }

    // TODO: PROB NEED SOME KIND OF ACCOUNTING CHANGE HERE TOO
    function totalAssetsOfUser(address _user) public view returns (uint256) {
        return asset.balanceOf(_user);
    }

    // OTHER PUBLIC FUNCTIONS

    function getExchangeRate() internal pure returns (uint256) {
        return 950000000000000000; // This represents 0.98 in fixed-point arithmetic with 18 decimal places

        // TODO: FINISH THIS LATER TO ACCESS AN ORACLE
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

    function addMockDestinationVault(address _mockDestinationVault) public onlyOwner {
        mockDestinationVault = IMockDestinationVault(_mockDestinationVault);
    }
    
    // CCIP MESSAGE FUNCTIONS    

    // TODO: IMPLEMENT THIS FUNCTION PROPERLY WITH CCIP
    function testTransferTokensToDestinationVault() public {
        emit FunctionCalledBy(msg.sender);
        uint256 balance = asset.balanceOf(address(this));
        require(balance > 0, "No tokens to transfer");

        // Transfer tokens to destination vault
        SafeTransferLib.safeTransfer(asset, address(mockDestinationVault), balance);

        mockDestinationVault.swapAndAppendBalance(balance);
        emit TEST_TokensTransferredToDestinationVault(balance);        
}

    function requestWithdrawalFromDestinationVault(uint64 _destinationChainSelector, address _receiver, address _token, uint256 _amount) public {
        // Withdrawal request implementation
    }

    function _ccipReceive(bytes memory _message) internal {
        // CCIP receive implementation
    }

    // RESTRICTED ACCESS FUNCTIONS
    function updateBalanceFromDestinationVault() external /* TODO: onlyDestinationVault */ {
        
        //TODO: IMPLEMENT THIS FUNCTION PROPERLY WITH CCIP
    }

    // In SourceVault contract
    function updateBalanceFromMockDestinationVault(uint256 _newBalance) external {
        // TODO: Add access control to ensure only MockDestinationVault can call this function
        mockDestinationVaultBalance = _newBalance;
        emit MockBalanceUpdated(_newBalance); // Consider adding an event for tracking
}

    
    
    function updateAccountingAndExit() external {

        // WORK ON THIS FUNCTION LATER - GET THE DEPOSIT FLOW FIGURED OUT FIRST AND IGNORE WITHDRAWALS UNTIL THAT IS INTEGRATED WITH CCIP
        // This function is for when a customer exits the the vault and removes their funds
        
    }

    function lockVault() internal {
        // Vault locking logic
        vaultLocked = true;
    }

    function unlockVault() external /* TODO: onlyDestinationVault */ {
        // Vault unlocking logic
        vaultLocked = false;
    }

    // DELETE BEFORE DEPLOYMENT
    function externalLockVault() external onlyOwner {
        lockVault();
    }

}