# Gelato Automation Examples

This repository contains examples of using Gelato Automation with different trigger types, fee payment models, and implementation approaches. It demonstrates how to automate smart contract executions using Gelato's services.

## Fee Payment Models

### 1. 1Balance Model
- Uses a prepaid balance system
- Simpler contract implementation
- Better for frequent or regular tasks
- No need to manage ETH in the contract

### 2. TransactionPaysItself Model
- Contract holds ETH to pay for transactions
- More complex fee handling
- Better for one-off or infrequent tasks
- Requires contract to be funded with ETH or native token

## Implementation Types

### 1. Solidity Functions
- Direct implementation in Solidity
- Simpler setup
- Good for basic automation needs

### 2. TypeScript Functions
- More complex logic possible
- Better for advanced automation needs
- Can handle more sophisticated conditions

## Examples and Task IDs

### Time Trigger Examples (deployed on Sepolia)
- **1Balance Solidity**: Task ID: 0x59aef5baff3b1359764eceacd11a31748a24d72d14aa555dab714bdab746834e
- **1Balance TypeScript**: Task ID: 0x02408b152e917cd023cba2ff38f8d290f84a7876e85bc5dd9ef8a77a7d4b7534
- **TransactionPaysItself Solidity**: Task ID: 0x44d7c07e71ca13bc7ecb5ca9109163d9ed87c9211d2d36f7f6714ba13083701e
- **TransactionPaysItself TypeScript**: Task ID: 0xb10b6d56b5e5babb42ca17dd8d6ead6219c886033df37960fef099b7681c6781

### Event Trigger Examples
- **1Balance Solidity**: Task ID: 0x20419b24c22199c4aa23d67b759f841a0cafd113847e59c2ee10b97a54a0d627
- **1Balance TypeScript**: Task ID: 0x0158c396b50a29a155a63fa16d2696ac84c7318154a5e06fe4dffa00f544926d
- **TransactionPaysItself Solidity**: Task ID: 0xd5a58382673a8e6b8c1ef6247a17fd4dd81e70b360caf71e10feb7ac5369392a
- **TransactionPaysItself TypeScript**: Task ID: 0xd49ae826e1d16a46c57ee81abe164f9e74179817f3a1405c0a0003435f4ccb96

### Single Execution Examples
- **1Balance Solidity**: Task ID: 0x5183d95e38da93bd7e9dd33e17681b55fe83e88127ae13c0f46c6f236a574219
- **1Balance TypeScript**: Task ID: 0xe0d49f33f19c11cb5671fc4ba3d006e4de73038f56397bacedefd02575ce55ab
- **TransactionPaysItself Solidity**: Task ID: 0x525d0d6edf8c7fab31fb2eefbfb60c6fd5bb9ea5ebe762f52fbc07799789bd8a
- **TransactionPaysItself TypeScript**: Task ID: 0xc401aaeb0ebbecb76e2d8ff387105e39b60a22b302d0da00953a970d7d31ab68

## Installation

Clone the repository and install its dependencies:

    ```bash
    git clone https://github.com/gelatodigital/gelato-solidity-functions-unit-testing.git
    cd gelato-solidity-functions-unit-testing
    yarn install
    ```

## Quick Start

1. Setup your local blockchain:
    ```bash
    yarn hardhat node
    ```

2. Deploy contracts:
    ```bash
    yarn hardhat deploy --network sepolia
    ```

3. Fund contracts (for TransactionPaysItself model):
    ```bash
    yarn hardhat run scripts/fundAndCreateTask.ts --network sepolia
    ```

## Testing

To run the tests:
    ```bash
    yarn hardhat test
    ```

## Project Structure

- `contracts/integrations/examples/contractCreator/1balance/`: 1Balance model examples
- `contracts/integrations/examples/contractCreator/transactionPaysItself/`: TransactionPaysItself model examples
- `scripts/`: Deployment and interaction scripts
- `test/`: Test files

## Contributing

Feel free to submit issues and enhancement requests.
