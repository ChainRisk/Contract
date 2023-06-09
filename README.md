# README

## ChainRisk NFT Contract

This repository contains the Solidity contract code for the ChainRisk project. The ChainRisk contract is a unique NFT contract that leverages Chainlink technology to store credit ratings from multiple agencies in a dynamic NFT.

---

## Features

- Creation of NFTs tied to a credit rating system
- Dynamic updating of NFT metadata
- Integration with Chainlink to facilitate decentralized, trustless data fetching
- Transferring and withdrawing of LINK tokens, used for Chainlink oracle requests

---

## Requirements

To interact with or deploy this contract, you'll need:

- [Node.js](https://nodejs.org/en/download/)
- [Truffle](https://www.trufflesuite.com/truffle) - A development environment, testing framework and asset pipeline for Ethereum.
- [Metamask](https://metamask.io/) - A crypto wallet & gateway to blockchain apps.

---

## Setup

1. Clone this repository
2. Install all dependencies by running `npm install` in your terminal
3. Create a .env file at the root of your project and add your MetaMask private key and Infura project ID (for deployment and interaction on the Polygon Mumbai testnet)

```bash
METAMASK_PRIVATE_KEY = "your_metamask_private_key"
INFURA_PROJECT_ID = "your_infura_project_id"
```

4. Compile the contract by running `truffle compile` in your terminal
5. Deploy the contract to the Polygon Mumbai testnet by running `truffle migrate --network matic`

---

## Testing

To run the tests for the contract, run `truffle test` in your terminal.

---

## Deployment

To deploy this contract to the Polygon Mumbai testnet, run `truffle migrate --network matic` in your terminal.

---

## Interacting with the contract

You can interact with the contract using Truffle console or programmatically using a script.

To open the Truffle console on the Polygon Mumbai testnet, run `truffle console --network matic` in your terminal.

---

## Future Improvements

- Implement ERC-4337 to allow users to approve and transfer tokens in a single transaction.
- Include API keys for personal ratings to enable personalization.
- Collaborate with real credit rating agencies to fetch real-world credit rating data.
- Improve the user experience with LINK payments.
- Update the contract to handle NFT expiration.
- Conduct a thorough security audit to ensure the solution's robustness.
