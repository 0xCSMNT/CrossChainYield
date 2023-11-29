# STIP-[xx]
*Using template v0.1*
## Abstract
Interacting with bridges is challenging and imposes a cost and time commitment on the user that is a sub-standard experience relative to traditional asset management
## Motivation
- Feature
An ERC4626 vault that can execute bridging and investments on the behalf of the user

- **Why is this feature necessary?**
    - To make yield opportunities available to users on their prefered chain
- **Who is this feature for?**
    - Managers: create vaults that include a more diverse set of assets and strategies
    - Investors: improved UI for allocating to opportunities beyond your prefered chain
- **When and how is this feature going to be used?**
    - any time a manager wants to abstract away cross chain interactions from their users


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
xxxx

### Chainlink CCIP
xxxx

### Li.Fi Bridge
Li.FI is a multichain bridge and DEX aggregator with support for most chains, bridges, and DEX aggregators as well as single DEXs. List of DEXs they support can be found [here](https://docs.li.fi/list-chains-bridges-dexs)

## Open Questions
_Pose any open questions you may still have about potential solutions here. We want to be sure that they have been resolved before moving ahead with talk about the implementation. This section should be living and breathing through out this process._
- [ ] What assets and what chain to use? Why?
    - *Answer*
- [ ] How can we use Li.Fi to execute the bridge and swap?
    - *Answer*
- [ ] Chainlink - what libraries & repos?
    - *Answer*
- [ ] Chainlink - CCIP how to?
    - *Answer*
- [ ] Chainlink - automation how to?
    - *Answer*
- [ ] Question
    - *Answer*
- [ ] Question
    - *Answer*

## Feasibility Analysis
Provide potential solution(s) including the pros and cons of those solutions and who are the different stakeholders in each solution. A recommended solution should be chosen here.
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
