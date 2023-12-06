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
    bool public vaultLocked;
    
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
        return asset.balanceOf(address(this));
    }

    function totalAssetsOfUser(address _user) public view returns (uint256) {
        return asset.balanceOf(_user);
    }

    // OTHER PUBLIC FUNCTIONS

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

    function transferTokensToDestinationVault(
        uint64 _destinationChainSelector,
        address _receiver,
        address _token,
        uint256 _amount
    ) 
        external
        onlyOwner
        onlyWhitelistedChains(_destinationChainSelector)
        returns (bytes32 messageId) 
    {
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({
            token: _token,
            amount: _amount
        });
        tokenAmounts[0] = tokenAmount;
        
        // Build the CCIP Message
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: abi.encodeWithSignature("test message", msg.sender),
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 200_000, strict: false})
            ),
            feeToken: address(linkToken)
        });
        
        // CCIP Fees Management
        uint256 fees = router.getFee(_destinationChainSelector, message);

        if (fees > linkToken.balanceOf(address(this)))
            revert NotEnoughBalance(linkToken.balanceOf(address(this)), fees);

        linkToken.approve(address(router), fees);
        
        // Approve Router to spend CCIP-BnM tokens we send
        IERC20(_token).approve(address(router), _amount);
        
        // Send CCIP Message
        messageId = router.ccipSend(_destinationChainSelector, message); 
        
        emit TokensTransferred(
            messageId,
            _destinationChainSelector,
            _receiver,
            _token,
            _amount,
            address(linkToken),
            fees
        );   
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