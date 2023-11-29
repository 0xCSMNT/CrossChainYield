# Spec Doc for CL Vault
*Using template v0.1*
## Abstract
Interacting with bridges is challenging and imposes a cost and time commitment on the user that is a sub-standard experience relative to traditional asset management
## Motivation
### Feature
- **Description**: An ERC4626 vault that can execute bridging and investments on behalf of the user.

### Why is this feature necessary?
- To make yield opportunities available to users on their preferred chain.

### Who is this feature for?
- **Managers**: Create vaults that include a more diverse set of assets and strategies.
- **Investors**: Improved UI for allocating to opportunities beyond your preferred chain.

### When and how is this feature going to be used?
- Used anytime a manager wants to abstract away cross-chain interactions from their users.

### User Story
Sandra has all of her funds on Base. She is a new DeFi user and just got a metamask account. She has heard about good yield on Avalanche AVAX, but is unsure about bridges and the idea of multiple wallets and chains.

Yield Getter (bad name) is a vault that she can easily deposit collateral into on Base, and on the backend it handles all of the bridging for her. She deposits ETH on Base and receives a share token that represents her claim on Staked AVAX on Avalanche.

## Background Information
_This section should contain any relevant info required for understanding the problem at hand. This may include any of the following:_
_- Previous work done on the topic_
_- Discussion of any relevant parts of the Set system_
_- Documentation on any external protocols to consider when designing the solution._ 
_Links are great but providing relevant interfaces AND a brief description of how the protocol works is a big plus, highlighting any nuances (ie in AAVE interest accrues by creating more aTokens vs Compound accrues by updating cToken to underlying exchange rate)_

### ERC4626
#### Examples & Contracts:
- [Solmate](https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
- [Open Zeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC4626.sol)
- A simple implementation on [QuickNode](https://www.quicknode.com/guides/ethereum-development/smart-contracts/how-to-use-erc-4626-with-your-smart-contract#what-you-will-need)
- Smart Contract Programmer [Vault Math](https://youtu.be/k7WNibJOBXE?si=kwVLuDNLKkWEQ1cc)

#### Accounting:
- **Deposit Asset**: Use wAVAX on source chain as deposit asset.
- **Yield Asset**: Use sAVAX on destination chain as yield asset.
- **Total Assets Calculation**: `totalAssets()` is defined in wAVAX according to the total of both and exchange rate between them.
- **Fetching Timestamp**: Call `historicalExchangeRateTimestamps(0)` to get `_timestamp`.
- **Getting Exchange Rate**: Call `historicalExchangeRateByTimestamps(_timestamp)` to get rate in wei.
- **Handling Execution Data**:
  - The challenge is obtaining execution data on swaps (slippage) and exchange rate back to the vault contracts on the destination chain to ensure the `totalAssets()` call is accurate.
  - Use CCIP for this purpose.
- **Keeper Role**:
  - A keeper grabs the exchange rate and execution data from the swap and returns it to the destination chain using CCIP.
  - Keeper on homechain executes a function to update `totalAssets()` based on this data.
- **Redemption Process**:
  - User shares on redeem are defined as their percentage of `totalSupply`.
  - User initiates a redeem call.
  - Calculate `user_withdrawal_perc = number of shares / totalSupply()`.
  - Determine the amount to transfer out: `amount to transfer out = user_withdrawal_perc * totalAssets()`.

### Chainlink Automation
- **Getting Started**: [Guide](https://docs.chain.link/chainlink-automation/overview/getting-started)
- **Better Guide**: [Time-based upkeeps](https://docs.chain.link/quickstarts/time-based-upkeep)
  - Time-based upkeeps are smart contracts set up using Chainlink Automation
      - Allow the automatic execution of a smart contract function on a custom schedule
      - Similar to cron jobs
      - Can be used to trigger smart contract functions.
  - Register a new upkeep on [automation.chain.link](automation.chain.link).
  - Use a cron expression to set the time interval. For example, `0 0 * * *` runs at midnight every 24 hours.
  - Consider setting upkeep to call some bridge function on the vault smart contract.
- **Custom Logic**: 
  - Import the right Chainlink libraries to set custom logic within your smart contract.
  - For Example, topping up a contract when the balance falls too low
  - Guide on Chainlink keeper: [CL Keeper - Guide](https://docs.chain.link/chainlink-automation/guides/compatible-contracts)

### Chainlink CCIP
- Install Foundry Chainlink Toolkit: `forge install smartcontractkit/foundry-chainlink-toolkit`
- Supported [Testnets](https://docs.chain.link/ccip/supported-networks/testnet)
- **Uniswap V2 [Deployment](https://sepolia.etherscan.io/address/0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008#code)** on Sepolia
- **[CCIP Test Tokens](https://docs.chain.link/ccip/test-tokens#mint-tokens-in-the-documentation)**:
  - **BnM**: These tokens are minted on each testnet. When transferring these tokens between testnet blockchains, CCIP burns the tokens on the source chain and mints them on the destination chain.
  - **LnM**: These tokens are only minted on Ethereum Sepolia. On other testnet blockchains, the token representation is a wrapped/synthetic asset called clCCIP-LnM. When transferring these tokens from Ethereum Sepolia to another testnet, CCIP locks the CCIP-LnM tokens on the source chain and mints the wrapped representation clCCIP-LnM on the destination chain. Between non-Ethereum Sepolia chains, CCIP burns and mints the wrapped representation clCCIP-LnM.

- **Open Question**:
    - How will the swap on the destination chain trigger the CCIP message to update the accounting?

- **Implementation Idea**:
    - If we can create our own CCIP BnM test tokens, we might not need to use a third-party bridge and can keep it all to onchain CL stack.
      - Could use the BnM token on Polygon Mumbai as the deposit asset.
      - Bridge it to Sepolia.
      - Swap it to another ERC we pair against it on Uni V2 deployment there.

### Chainlink Functions
- Call any API from a smart contract: Enables access to off-chain data and computation.
  - [Overview](https://chain.link/functions) and [docs](https://docs.chain.link/chainlink-functions)
  - Good [Video](https://youtu.be/I-g1aaZ3_x4?si=gKw8ccZS5__Kj0mD0 to get up to speed
  - Could be useful for interacting with **Li.Fi API**


### Li.Fi
Li.FI is a multichain bridge and DEX aggregator with support for most chains, bridges, and DEX aggregators as well as single DEXs. List of DEXs they support can be found [here](https://docs.li.fi/list-chains-bridges-dexs). 

* [LiFi Widget](https://docs.li.fi/integrate-li.fi-widget/li.fi-widget-overview) has a set of Prebuilt UI components that will help integrate cross-chain bridging and swapping experince. 

* [LiFi APIs](https://docs.li.fi/li.fi-api/li.fi-api) can be used to transfer tokens, request supported chains and tokens, token information, and all possible connections. You can also request status of transactions via the API. 

* [LiFi SDK](https://docs.li.fi/integrate-li.fi-js-sdk/install-li.fi-sdk) package allows access to Li.Fi API, and find the best cross chain routes on different bridges and exchanges. The routes can then be executed via the SDK.

- **Integration and Functionality Questions**:
  - How will the bridge talk to the smart contract?
  - Noting the challenge that the li.fi API/SDK uses web 2 to get quotes and confirm transactions.
  - Chainlink Automation triggers smart contract functions.
  - Consideration: Maybe use Chainlink Functions (a different CL product) for off-chain logic and interacting with Li.Fi?

- **Li.Fi Testnet Deployments**:
  - Ethereum Goerli
  - Polygon Mumbai

## Open Questions
_Pose any open questions you may still have about potential solutions here. We want to be sure that they have been resolved before moving ahead with talk about the implementation. This section should be living and breathing through out this process._
- [ ] What assets and what chain to use? Why?
    - *Answer*
- [ ] How can we use Li.Fi to execute the bridge and swap?
    - *With a webapp or with a Chainlink Function*
- [ ] Chainlink - what libraries & repos?
    - *Answer*
- [ ] Chainlink - CCIP how to?
    - *Answer*
- [ ] Chainlink - automation how to?
    - *Answer*
- [ ] What testnet deployments are ruled out by picking specific technologies
    - *For example: Li.Fi is not on Sepolia*
- [ ] Question
    - *Answer*

## Feasibility Analysis
Provide potential solution(s) including the pros and cons of those solutions and who are the different stakeholders in each solution. A recommended solution should be chosen here. A combination of the below solutions will be used for accomplishing the goals of the project.

### Options 
1. **Bridging Solution A** - Use Li.Fi to bridge, and native destination chain swap 
2. **Bridging Solution B** - Use Chainlink CCIP to send tokens and then use native destination chain swap 
3. **Custody Solution A** - User Funds on Destination Chain sit in an EOA and cannot be redeemed (one way trip)
4. **Custody Solution B** - User Funds on Destination Chain are in a seperate vault that users can withdraw from (much more complicated but possible with CCIP I think)

#### Bridging Solution A using CL Functions and Li.Fi API
- User deposits asset A to an ERC4626 Vault
- Every 24 hours a Chainlink Function interacts with the LiFi API to RFQ a quote to bridge and swap
    - (this may require a chainlink automation keeper to trigger the call to the Function)
-  The data from quote is passed to a `bridge assets()` function on the vault smart contract as argument and bridge and swap is executed
-  On the destination chain a chainlink keeper watches for the new asset and grabs the execution data for the swap - slippage etc
-  This execution data is passed back to the home chain vault by CCIP
-  This data is then used by a `updateAssets()` function that updates the accouting on the vault

#### Bridging Solution B using CCIP
- Similar to the above but must use `CCIP-BnM` test tokens as deposit asset in vault and requires us to deploy a UNI V2 Pool on Sepolia that pairs the `CCIP-BnM` token against a ERC20 that we deploy
- User deposits token to Vault
- Every 24 hours a CL keeper triggers a bridge and swap using CCIP
- Call data for the swap is sent with the asset
- Swap is executed on Uni pool

#### Custody Solution A using a EOA or very simple smart contract
- We basically build the bare minimum required to hold the asset and allow the swap once it has been bridged
- Pro: Easier to build and test, faster to deploy
- Con: One way trip for users. They are never getting money back...

#### Custody Solution B using another vault
- We deploy another 4626 on the destination chain that accepts the bridged assets
- When a user wishes to withdraw their money, they burn their shares on the home chain and this creates a CCIP message to the destination chain vault to mint shares for them to withdraw.
- Pro: User can redeem their assets
- Con: Harder to build, more places for accounting to mess up

#### Locking & Security
- As an additional precaution we can create a way to lock the vault when the bridge and swap is being executed
- For Example:
    - We lock the home chain vault (no deposits, withdrawals, mint, redeems etc) with the same CL keeper command that executes the bridge and swap
    - Once the swap has been executed on the destination chain, we can send a call back to the source chain to unlock the vault
    
## Timeline
A proposed timeline for completion

## Checkpoint 1
Before more in depth design of the contract flows lets make sure that all the work done to this point has been exhaustive. It should be clear what we're doing, why, and for who. All necessary information on external protocols should be gathered and potential solutions considered. At this point we should be in alignment with product on the non-technical requirements for this feature. It is up to the reviewer to determine whether we move onto the next step.

**Reviewer**:

## Proposed Architecture Changes
A diagram would be helpful here to see where new feature slot into the system. Additionally a brief description of any new contracts is helpful.
## Requirements
These should be a distillation of the previous two sections taking into account the decided upon high-level implementation. Each flow should have high level requirements taking into account the needs of participants in the flow (users, managers, market makers, app devs, etc) 
## User Flows
- Highlight *each* external flow enabled by this feature. It's helpful to use diagrams (add them to the `assets` folder). Examples can be very helpful, make sure to highlight *who* is initiating this flow, *when* and *why*. A reviewer should be able to pick out what requirements are being covered by this flow.
## Checkpoint 2
Before we spec out the contract(s) in depth we want to make sure that we are aligned on all the technical requirements and flows for contract interaction. Again the who, what, when, why should be clearly illuminated for each flow. It is up to the reviewer to determine whether we move onto the next step.

**Reviewer**:

Reviewer: []
## Specification
### [Contract Name]
#### Inheritance
- List inherited contracts
#### Structs
| Type 	| Name 	| Description 	|
|------	|------	|-------------	|
|address|manager|Address of the manager|
|uint256|iterations|Number of times manager has called contract|  
#### Constants
| Type 	| Name 	| Description 	| Value 	|
|------	|------	|-------------	|-------	|
|uint256|ONE    | The number one| 1       	|
#### Public Variables
| Type 	| Name 	| Description 	|
|------	|------	|-------------	|
|uint256|hodlers|Number of holders of this token|
#### Functions
| Name  | Caller  | Description 	|
|------	|------	|-------------	|
|startRebalance|Manager|Set rebalance parameters|
|rebalance|Trader|Rebalance SetToken|
|ripcord|EOA|Recenter leverage ratio|
#### Modifiers
> onlyManager(SetToken _setToken)
#### Functions
> issue(SetToken _setToken, uint256 quantity) external
- Pseudo code
## Checkpoint 3
Before we move onto the implementation phase we want to make sure that we are aligned on the spec. All contracts should be specced out, their state and external function signatures should be defined. For more complex contracts, internal function definition is preferred in order to align on proper abstractions. Reviewer should take care to make sure that all stake holders (product, app engineering) have their needs met in this stage.

**Reviewer**:

## Implementation
[Link to implementation PR]()
## Documentation
[Link to Documentation on feature]()
## Deployment
[Link to Deployment script PR]()  
[Link to Deploy outputs PR]()
