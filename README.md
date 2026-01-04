# MantleVerifi

ZK-Powered Identity and Compliance Protocol for Real-World Assets on Mantle Network.

## Overview

MantleVerifi is a decentralized identity and compliance protocol that enables institutional-grade compliance with user-centric privacy. Users can verify their credentials (e.g., accredited investor status) using zero-knowledge proofs and receive a non-transferable Soul-Bound Token (SBT) as proof of verification.

## Features

- **Privacy-Preserving Verification**: ZK proofs allow verification without exposing personal data
- **Soul-Bound Tokens (SBT)**: Non-transferable credentials following EIP-5192
- **Reusable Credentials**: One verification grants access to all integrated RWA protocols
- **Compliance Ready**: Built for institutional requirements (accredited investor, qualified purchaser, etc.)

## Project Structure

```
mantle-verifi/
├── packages/
│   ├── contracts/       # Solidity smart contracts
│   ├── frontend/        # Next.js frontend application
│   └── zkp/             # Mock ZK proof generation library
├── docs/                # Documentation
└── README.md
```

## Smart Contracts

| Contract | Description |
|----------|-------------|
| `VerifiSBT.sol` | EIP-5192 compliant Soul-Bound Token |
| `ZKVerifier.sol` | Mock ZK proof verification |
| `CredentialRegistry.sol` | Credential type management |
| `RWAGate.sol` | Demo permissioned investment pool |

## Credential Types

| ID | Type | Description |
|----|------|-------------|
| 1 | Accredited Investor | US SEC accredited investor status |
| 2 | Qualified Purchaser | SEC qualified purchaser ($5M+ assets) |
| 3 | Non-US Person | Non-US person verification |
| 4 | KYC Basic | Basic identity verification |
| 5 | Institution | Institutional investor status |

## Getting Started

### Prerequisites

- Node.js v18+
- npm or yarn
- A wallet with MNT (for testnet deployment)

### Installation

```bash
# Clone the repository
cd mantle-verifi

# Install dependencies
npm install

# Build all packages
npm run build
```

### Smart Contracts

```bash
cd packages/contracts

# Compile contracts
npm run compile

# Run tests
npm run test

# Deploy to Mantle Sepolia
PRIVATE_KEY=your_key npm run deploy
```

### Frontend

```bash
cd packages/frontend

# Install dependencies
npm install

# Run development server
npm run dev
```

Open http://localhost:3000 in your browser.

## How It Works

1. **Connect Wallet**: User connects their wallet to the dApp
2. **Select Credential**: User selects the credential type to verify
3. **Mock Verification**: Simulates off-chain KYC verification
4. **Generate ZK Proof**: Creates a privacy-preserving proof
5. **Mint SBT**: Mints a Soul-Bound Token as proof of verification
6. **Access RWA Pools**: User can now access permissioned DeFi protocols

## Network Configuration

| Parameter | Value |
|-----------|-------|
| Network | Mantle Sepolia |
| Chain ID | 5003 |
| RPC URL | https://rpc.sepolia.mantle.xyz |
| Explorer | https://explorer.sepolia.mantle.xyz |

## Technical Stack

- **Smart Contracts**: Solidity 0.8.20+, Hardhat, OpenZeppelin
- **Frontend**: Next.js 14, React, Tailwind CSS
- **Web3**: wagmi v2, viem
- **ZK (Mock)**: TypeScript simulation of SP1 zkVM

## Future Improvements

- [ ] Integrate actual SP1 zkVM for real ZK proofs
- [ ] Connect to real KYC providers
- [ ] Add more credential types
- [ ] Multi-chain credential portability
- [ ] Credential expiry and renewal flows

## License

MIT

## Acknowledgments

- Built for Mantle Global Hackathon 2025
- Inspired by Polygon ID, Ondo Finance, and Centrifuge
- References EIP-5192 (Soulbound NFTs) and ERC-3643 (T-REX)
