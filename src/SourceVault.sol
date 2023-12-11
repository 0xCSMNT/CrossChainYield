// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "lib/solmate/src/utils/FixedPointMathLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";
import {ERC4626} from "lib/solmate/src/mixins/ERC4626.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {PriceConverter} from "src/PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// TODO: CREATE PROPER CONTRACT DESCRIPTION

struct Log {
    uint256 index; // Index of the log in the block
    uint256 timestamp; // Timestamp of the block containing the log
    bytes32 txHash; // Hash of the transaction containing the log
    uint256 blockNumber; // Number of the block containing the log
    bytes32 blockHash; // Hash of the block containing the log
    address source; // Address of the contract that emitted the log
    bytes32[] topics; // Indexed topics of the log
    bytes data; // Data of the log
}

interface ILogAutomation {
    function checkLog(
        Log calldata log,
        bytes memory checkData
    ) external returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;
}

contract SourceVault is ERC4626, OwnerIsCreator, CCIPReceiver, ILogAutomation {
    // STATE VARIABLES
    IERC20 private s_linkToken;
    address public destinationVault;
    bool public vaultLocked;
    address public CCIP_BnM;
    address immutable router;
    AggregatorV3Interface public priceFeed;
    uint256 public DestinationVaultBalance;

    bytes32 private s_lastReceivedMessageId; // Store the last received messageId.
    address private s_lastReceivedTokenAddress; // Store the last received token address.
    uint256 private s_lastReceivedTokenAmount; // Store the last received amount.
    string private s_lastReceivedText; // Store the last received text.

    mapping(uint64 => bool) public allowlistedDestinationChains;
    mapping(uint64 => bool) public allowlistedSourceChains;
    mapping(address => bool) public allowlistedSenders;

    constructor(
        address _router,
        address _link,
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        address _priceFeed
    ) CCIPReceiver(_router) ERC4626(_asset, _name, _symbol) {
        router = _router;
        s_linkToken = IERC20(_link);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    // Custom errors to provide more descriptive revert messages.
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance to cover the fees.
    error NothingToWithdraw(); // Used when trying to withdraw Ether but there's nothing to withdraw.
    error FailedToWithdrawEth(address owner, address target, uint256 value); // Used when the withdrawal of Ether fails.
    error DestinationChainNotAllowed(uint64 destinationChainSelector); // Used when the destination chain has not been allowlisted by the contract owner.
    error SourceChainNotAllowed(uint64 sourceChainSelector); // Used when the source chain has not been allowlisted by the contract owner.
    error SenderNotAllowed(address sender); // Used when the sender has not been allowlisted by the contract owner.

    // Event emitted when a message is sent to another chain.
    event MessageSent(
        bytes32 indexed messageId, // The unique ID of the CCIP message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        string text, // The text being sent.
        address token, // The token address that was transferred.
        uint256 tokenAmount, // The token amount that was transferred.
        address feeToken, // the token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the message.
    );

    // Event emitted when a message is received from another chain.
    event MessageReceived(
        bytes32 indexed messageId, // The unique ID of the CCIP message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address sender, // The address of the sender from the source chain.
        string text, // The text that was received.
        address token, // The token address that was transferred.
        uint256 tokenAmount // The token amount that was transferred.
    );
    event AccountingUpdated(uint256 totalAssets);
    event TEST_TokensTransferredToDestinationVault(uint256 amount);
    event FunctionCalledBy(address caller);
    event DestinationVaultBalanceUpdated(uint256 newBalance);
    event UpkeepExecuted(address logSender);

    ///CCIP specific modifiers and mappings

    modifier onlyAllowlistedDestinationChain(uint64 _destinationChainSelector) {
        if (!allowlistedDestinationChains[_destinationChainSelector])
            revert DestinationChainNotAllowed(_destinationChainSelector);
        _;
    }
    /// @dev Modifier that checks if the chain with the given sourceChainSelector is allowlisted and if the sender is allowlisted.
    /// @param _sourceChainSelector The selector of the destination chain.
    /// @param _sender The address of the sender.
    modifier onlyAllowlisted(uint64 _sourceChainSelector, address _sender) {
        if (!allowlistedSourceChains[_sourceChainSelector])
            revert SourceChainNotAllowed(_sourceChainSelector);
        if (!allowlistedSenders[_sender]) revert SenderNotAllowed(_sender);
        _;
    }

    modifier onlyRouterOrOwner() {
        require(
            msg.sender == router || msg.sender == owner(),
            "Only LPSC or Owner can call"
        );
        _;
    }

    function allowlistDestinationChain(
        uint64 _destinationChainSelector,
        bool allowed
    ) external onlyOwner {
        allowlistedDestinationChains[_destinationChainSelector] = allowed;
    }

    /// @dev Updates the allowlist status of a source chain
    /// @notice This function can only be called by the owner.
    /// @param _sourceChainSelector The selector of the source chain to be updated.
    /// @param allowed The allowlist status to be set for the source chain.
    function allowlistSourceChain(
        uint64 _sourceChainSelector,
        bool allowed
    ) external onlyOwner {
        allowlistedSourceChains[_sourceChainSelector] = allowed;
    }

    /// @dev Updates the allowlist status of a sender for transactions.
    /// @notice This function can only be called by the owner.
    /// @param _sender The address of the sender to be updated.
    /// @param allowed The allowlist status to be set for the sender.
    function allowlistSender(address _sender, bool allowed) external onlyOwner {
        allowlistedSenders[_sender] = allowed;
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
        uint256 _destinationVaultBalance = FixedPointMathLib.mulDivUp(
            DestinationVaultBalance,
            1e18,
            getExchangeRate()
        );
        uint256 _totalAssets = _depositAssetBalance + _destinationVaultBalance;
        return _totalAssets;
    }

    // TODO: PROB NEED SOME KIND OF ACCOUNTING CHANGE HERE TOO
    function totalAssetsOfUser(address _user) public view returns (uint256) {
        return asset.balanceOf(_user);
    }

    // OTHER PUBLIC FUNCTIONS

    function getExchangeRate() internal view returns (uint256) {
        uint256 price = PriceConverter.getPrice(priceFeed);
        return price;
    }

    // TODO: Keeper here
        
    function sendMessagePayLINK(
    uint64 _destinationChainSelector,
    address _receiver,
    string calldata _text,
    address _token
)
    public      
    returns (bytes32 messageId)
{
    // Determine the amount based on the balance of the asset held by the contract
    uint256 _amount = IERC20(_token).balanceOf(address(this));

    // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
    // address(linkToken) means fees are paid in LINK
    Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
        _receiver,
        _text,
        _token,
        _amount,
        address(s_linkToken)
    );

    // Initialize a router client instance to interact with cross-chain router
    IRouterClient routerClient = IRouterClient(this.getRouter());

    // Get the fee required to send the CCIP message
    uint256 fees = routerClient.getFee(_destinationChainSelector, evm2AnyMessage);

    if (fees > s_linkToken.balanceOf(address(this)))
        revert NotEnoughBalance(s_linkToken.balanceOf(address(this)), fees);

    // approve the Router to transfer LINK tokens on contract's behalf. It will spend the fees in LINK
    s_linkToken.approve(address(router), fees);

    // approve the Router to spend tokens on contract's behalf. It will spend the amount of the given token
    IERC20(_token).approve(address(router), _amount);

    // Send the message through the router and store the returned message ID
    messageId = routerClient.ccipSend(_destinationChainSelector, evm2AnyMessage);

    // Emit an event with message details
    emit MessageSent(
        messageId,
        _destinationChainSelector,
        _receiver,
        _text,
        _token,
        _amount,
        address(s_linkToken),
        fees
    );

    // Return the message ID
    return messageId;
}


    /// @notice Construct a CCIP message.
    /// @dev This function will create an EVM2AnyMessage struct with all the necessary information for programmable tokens transfer.
    /// @param _receiver The address of the receiver.
    /// @param _text The string data to be sent.
    /// @param _token The token to be transferred.
    /// @param _amount The amount of the token to be transferred.
    /// @param _feeTokenAddress The address of the token used for fees. Set address(0) for native gas.
    /// @return Client.EVM2AnyMessage Returns an EVM2AnyMessage struct which contains information for sending a CCIP message.
    function _buildCCIPMessage(
        address _receiver,
        string calldata _text,
        address _token,
        uint256 _amount,
        address _feeTokenAddress
    ) internal pure returns (Client.EVM2AnyMessage memory) {
        // Set the token amounts
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: _token,
            amount: _amount
        });
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_receiver), // ABI-encoded receiver address
                data: abi.encode(_text), // ABI-encoded string
                tokenAmounts: tokenAmounts, // The amount and type of token being transferred
                extraArgs: Client._argsToBytes(
                    // Additional arguments, setting gas limit and non-strict sequencing mode
                    Client.EVMExtraArgsV1({gasLimit: 1_000_000, strict: false})
                ),
                // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
                feeToken: _feeTokenAddress
            });
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    )
        internal
        override
        onlyAllowlisted(
            any2EvmMessage.sourceChainSelector,
            abi.decode(any2EvmMessage.sender, (address))
        ) // Make sure source chain and sender are allowlisted
    {
        s_lastReceivedMessageId = any2EvmMessage.messageId; // fetch the messageId
        s_lastReceivedText = abi.decode(any2EvmMessage.data, (string)); // abi-decoding of the sent text
        // Expect one token to be transferred at once, but you can transfer several tokens.
        s_lastReceivedTokenAddress = any2EvmMessage.destTokenAmounts[0].token;
        s_lastReceivedTokenAmount = any2EvmMessage.destTokenAmounts[0].amount;

        emit MessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector, // fetch the source chain identifier (aka selector)
            abi.decode(any2EvmMessage.sender, (address)), // abi-decoding of the sender address,
            abi.decode(any2EvmMessage.data, (string)),
            any2EvmMessage.destTokenAmounts[0].token,
            any2EvmMessage.destTokenAmounts[0].amount
        );
    }

    /**
     * @notice Returns the details of the last CCIP received message.
     * @dev This function retrieves the ID, text, token address, and token amount of the last received CCIP message.
     * @return messageId The ID of the last received CCIP message.
     * @return text The text of the last received CCIP message.
     * @return tokenAddress The address of the token in the last CCIP received message.
     * @return tokenAmount The amount of the token in the last CCIP received message.
     */
    function getLastReceivedMessageDetails()
        public
        view
        returns (
            bytes32 messageId,
            string memory text,
            address tokenAddress,
            uint256 tokenAmount
        )
    {
        return (
            s_lastReceivedMessageId,
            s_lastReceivedText,
            s_lastReceivedTokenAddress,
            s_lastReceivedTokenAmount
        );
    }

    // TODO: KEEPER HERE. CHECKS LAST MESSAGE AND UPDATES MOCK BALANCE
    function updateBalanceForDestinationVault()
        public
    /* TODO: onlyDestinationVault */ {
        DestinationVaultBalance = parseInt(s_lastReceivedText);
        emit DestinationVaultBalanceUpdated(DestinationVaultBalance);
    }

    function parseInt(string memory _value) internal pure returns (uint256) {
        uint256 result = 0;
        bytes memory b = bytes(_value);
        for (uint256 i = 0; i < b.length; i++) {
            require(
                uint8(b[i]) >= 48 && uint8(b[i]) <= 57,
                "Invalid character in the string"
            );

            // Subtract the ASCII value of '0' to get the numeric value
            uint256 digit = uint256(uint8(b[i])) - uint256(uint8(bytes1("0")));

            // Update the result by multiplying it by 10 and adding the digit
            result = result * 10 + digit;
        }
        return result;
    }

    function checkLog(
        Log calldata log,
        bytes memory
    ) external pure returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = true;
        address logSender = bytes32ToAddress(log.topics[1]);
        performData = abi.encode(logSender);
    }

    function performUpkeep(bytes calldata performData) public {
        address logSender = abi.decode(performData, (address));
        updateBalanceForDestinationVault();
        emit UpkeepExecuted(logSender);
    }

    function bytes32ToAddress(bytes32 _address) public pure returns (address) {
        return address(uint160(uint256(_address)));
    }
}
