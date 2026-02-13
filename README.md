# Credence

Production-grade ERC-3643 compliant identity and compliance protocol for Real-World Assets on Mantle Network.

## Overview

Credence is a decentralized identity and compliance protocol that enables institutional-grade compliance with user-centric privacy. Users can verify their credentials using SP1 zero-knowledge proofs and receive non-transferable Soul-Bound Tokens (SBTs) as proof of verification.

## Architecture

```
credence/
├── packages/
│   ├── contracts/                 # Solidity smart contracts
│   │   ├── contracts/
│   │   │   ├── token/            # ERC-3643 compliant token
│   │   │   ├── registry/         # Identity & claims registries
│   │   │   ├── compliance/       # Modular compliance system
│   │   │   ├── verifier/         # SP1 zkVM integration
│   │   │   ├── sbt/              # EIP-5192 Soul-Bound Token
│   │   │   └── rwa/              # RWA investment gating
│   │   ├── scripts/              # Deployment scripts
│   │   └── test/                 # Contract tests
│   ├── zkp-rust/                 # SP1 Rust zkVM program
│   │   ├── program/              # ZK circuit for credential verification
│   │   └── script/               # Proof generation script
│   └── frontend/                 # Next.js 14 frontend (TBD)
└── README.md
```

## Smart Contracts

### Core Contracts

| Contract | Description |
|----------|-------------|
| `VerifiToken.sol` | ERC-3643 compliant security token with identity verification |
| `IdentityRegistry.sol` | Links wallet addresses to OnchainID identities |
| `ClaimTopicsRegistry.sol` | Manages required claim topics for verification |
| `TrustedIssuersRegistry.sol` | Manages trusted claim issuers |
| `ModularCompliance.sol` | Modular compliance engine for transfer restrictions |

### Compliance Modules

| Module | Description |
|--------|-------------|
| `CountryRestrictModule.sol` | Restricts transfers by country (allowlist/blocklist) |
| `AccreditedInvestorModule.sol` | Requires accredited investor status |

### Verification & Credentials

| Contract | Description |
|----------|-------------|
| `SP1CredentialVerifier.sol` | Verifies SP1 zero-knowledge proofs on-chain |
| `CredentialSBT.sol` | EIP-5192 Soul-Bound Token for verified credentials |

### RWA Investment

| Contract | Description |
|----------|-------------|
| `RWAGate.sol` | Investment gating based on credentials |
| `RWAPool.sol` | Investment pool with compliance checks |

## Credential Types

| ID | Type | Description |
|----|------|-------------|
| 1 | KYC | Basic identity verification |
| 2 | Accredited Investor | SEC accredited investor status |
| 3 | Qualified Purchaser | SEC qualified purchaser ($5M+ assets) |
| 4 | Institutional | Institutional investor status |
| 5 | AML | Anti-money laundering verification |

## Getting Started

### Prerequisites

- Node.js v18+
- Rust (for ZK proof generation)
- A wallet with MNT (for testnet deployment)

### Installation

```bash
# Install contract dependencies
cd packages/contracts
bun install

# Compile contracts
bun run compile

# Run tests
bun run test
```

### Deployment

```bash
# Copy environment file
cp .env.example .env

# Edit with your private key
nano .env

# Deploy to Mantle Sepolia
bun run deploy:mantle-sepolia
```

### Building ZK Proofs (Rust)

```bash
cd packages/zkp-rust

# Build the SP1 program
cd program && cargo build --release

# Generate a proof
cd ../script && cargo run --release -- --credential sample
```

## Network Configuration

| Parameter | Value |
|-----------|-------|
| Network | Mantle Sepolia |
| Chain ID | 5003 |
| RPC URL | https://rpc.sepolia.mantle.xyz |
| Explorer | https://sepolia.mantlescan.xyz |

## Technical Stack

- **Smart Contracts**: Solidity 0.8.24, Hardhat, OpenZeppelin 5.x
- **Standards**: ERC-3643 (T-REX), EIP-5192 (Soulbound)
- **ZK Proofs**: Succinct Labs SP1 zkVM
- **Frontend**: Next.js 14, wagmi v2, viem (TBD)

## ERC-3643 Compliance

This implementation follows the ERC-3643 T-REX protocol:

1. **Identity Registry**: Links wallets to OnchainID identities
2. **Claim Topics Registry**: Defines required verification topics
3. **Trusted Issuers Registry**: Manages authorized claim issuers
4. **Modular Compliance**: Pluggable compliance modules
5. **Transfer Restrictions**: All transfers check identity and compliance

## SP1 ZK Integration

The SP1 credential verifier program:
1. Verifies credential signatures from trusted issuers
2. Checks credential expiration
3. Validates required claim types
4. Outputs public values for on-chain verification

## Security Considerations

- All transfers require identity verification
- Compliance modules are checked before every transfer
- SBTs are non-transferable (soulbound)
- Agent roles for administrative operations
- Pausable tokens for emergency situations
- Proof replay prevention

## License

MIT

## Acknowledgments

- Built for Mantle Global Hackathon 2025
- Based on ERC-3643 T-REX Protocol
- SP1 zkVM by Succinct Labs
- OpenZeppelin Contracts
