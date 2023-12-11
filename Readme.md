# Crosschain Yield Project

## Overview

The Crosschain Yield Project aims to simplify and enhance the experience of yield opportunities across different blockchain networks. It leverages the power of Chainlink's Cross-Chain Interoperability Protocol (CCIP) to enable seamless cross-chain interactions, focusing on providing users with easy access to yield strategies regardless of the blockchain they prefer. This project targets a hackathon audience, demonstrating innovative use of cross-chain technology to solve real-world DeFi challenges.

### Key Features

- **Cross-Chain Vault Mechanism**: Utilizes ERC4626 standard for vault implementation, ensuring standardization and compatibility within the DeFi ecosystem.
- **Chainlink CCIP Integration**: Employs Chainlink's CCIP for reliable, secure cross-chain communication and token transfers.
- **Automated Yield Strategies**: Implements automated strategies to optimize yield across different blockchains.
- **Security and Efficiency**: Focuses on security measures like vault locking during critical operations and efficient accounting practices for user deposits and withdrawals.

## Architecture

The project consists of several interconnected components working across two blockchain networks: Avalanche Fuji (Source Chain) and Ethereum Sepolia (Destination Chain).

### Components

1. **SourceVault (Avalanche Fuji)**
   - Manages user deposits and withdrawals.
   - Executes cross-chain interactions for yield optimization.
   - Integrates with Chainlink CCIP for cross-chain messaging and token transfers.

2. **DestinationVault (Ethereum Sepolia)**
   - Receives tokens from the SourceVault.
   - Implements yield strategies on the destination chain.
   - Communicates with the SourceVault to update accounting information.

3. **ExitVault (Avalanche Fuji)**
   - Acts as an intermediary for users withdrawing their assets.
   - Ensures secure and orderly processing of withdrawal requests.

### Technologies

- Solidity for smart contract development.
- Chainlink's CCIP for cross-chain functionality.
- ERC4626 standard for vault implementation.
- Chainlink Automation for scheduled tasks and automated triggers.
