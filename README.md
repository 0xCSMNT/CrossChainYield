# SourceVault Contract Checklist

## Structs
- [ ] Define any custom structs

## State Variables
- [x] `IRouterClient public router`
- [x] `LinkTokenInterface linkToken`
- [x] `address public destinationVault`
- [x] `address public exitVault`
- [x] `mapping(uint64 => bool) public whitelistedChains`

## Events
- [x] `event TokenBridged(address indexed token, uint256 amount)`
- [x] `event AccountingUpdated(uint256 totalAssets)`

## Modifiers
- [x] `onlyWhitelistedChains(uint64 _chainId)`
- [ ] `onlyDestinationVault()`
- [ ] `onlyExitVault()`

## Constructor
- [x] Implement constructor with required parameters

## ERC4626 Functions
- [x] `_deposit(uint _assets)`
- [x] `_withdraw(uint _shares, address _receiver)`
    - [ ] Implement logic for when a bridging event is required to withdraw.
- [x] `totalAssets()`
- [x] `totalAssetsOfUser(address _user)`

## Other Public Functions
- [ ] `updateAccounting()` called by CCIP message to update assets and shares
- [x] `whitelistChain(uint64 _chainId)`
- [x] `denylistChain(uint64 _chainId)`
- [x] `addExitVault(address _exitVault)`
- [x] `addDestinationVault(address _destinationVault)`

## CCIP Message Functions
- [ ] `transferTokensToDestinationVault(uint64 _destinationChainSelector, address _receiver, address _token, uint256 _amount)`
- [ ] `requestWithdrawalFromDestinationVault(uint64 _destinationChainSelector, address _receiver, address _token, uint256 _amount)`
- [ ] `_ccipReceive(bytes memory _message)`

## Restricted Access Functions
- [ ] `exitAndUpdate()`
- [ ] `lockVault()`
- [ ] `unlockVault()`

# ExitVault Contract Checklist

## Structs
- [ ] Define any custom structs if required

## State Variables
- [x] `IRouterClient public router`
- [x] `LinkTokenInterface linkToken`
- [x] `address public sourceVault`
- [x] `address public destinationVault`
- [x] `mapping(uint64 => bool) public whitelistedChains`
- [x] `mapping(address => uint256) public withdrawalLimit`

## Events
- [x] `event TokenReceivedFromBridge(address indexed token, uint256 amount)`
- [x] `event TokenWithdrawanByCustomer(uint256 amount)`

## Modifiers
- [x] `onlyWhitelistedChains(uint64 _chainId)`
- [x] `onlyDestinationVault(address _sender)`

## Constructor
- [ ] Implement constructor with required parameters (if necessary)

## Other Public Functions
- [x] `setSourceVault(address _sourceVault)`
- [x] `setDestinationVault(address _destinationVault)`
- [x] `whitelistChain(uint64 _chainId)`

## CCIP Message Functions
- [ ] Implement any required CCIP message-related functions

## Restricted Access Functions
- [ ] Implement any functions restricted to specific roles

## Additional Logic
- [ ] Implement additional functionalities as per the contract requirements

