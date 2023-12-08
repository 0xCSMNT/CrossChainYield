
# CrossChainYield Aggregator 

## Important Contracts

## Destination Vault 

The constructor requires router address, LINK address, and source vault address while deploying. 

Destination vault accepts CCIP transfers and keeps the token balance updated. 

CCIP-BnM, the CCIP test token, is the *Base* asset. 

CCIP-DAI, is a test yield token deployed to swap test tokens against, on a Uniwap V2 pool setup on Sepolia. It is the *yield* asset. 

Calling `swapBaseBalanceToYield()` will swap all the base asset balance to the yield asset. This function has a `onlyOwner()` modifier. 

Calling `sendYieldBalancePayLINK` will send the Yield Asset balance (converted to String) to the the source vault on the source chain. 

To test, 

* You can send BnM to the contract via an EOA directly on sepolia and call the functions above.

* You can also send BnM via Fuji or another chain and then test. Make sure to whitelist the source address and chain via `allowlistsender()` and `allowSourceChain()`. 
















