# ETH Transfer Contract

A simple Ethereum smart contract project that implements transfer functionality for ETH and ERC20 tokens.

## Features

- ETH transfer functionality
- ERC20 token transfer support
- Comprehensive test suite
- Deployment scripts for Sepolia testnet

## Project Structure

```
├── src/               # Smart contracts
├── test/              # Test files
├── script/            # Deployment scripts
├── lib/               # Dependencies
├── foundry.toml       # Foundry configuration
└── .env.example       # Environment variables template
```

## Setup

1. Copy `.env.example` to `.env` and fill in your API keys
2. Install dependencies: `forge install`
3. Compile contracts: `forge build`
4. Run tests: `forge test`

## Deployment

Deploy to Sepolia testnet:
```bash
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify
```

## Requirements

- Foundry toolkit
- Alchemy API key for RPC access
- Etherscan API key for contract verification
- Private key for deployment