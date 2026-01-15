# Credence Architecture

## System Overview

Credence is a production-grade ERC-3643 compliant identity and compliance protocol for Real-World Assets on Mantle Network. It combines zero-knowledge proofs (SP1), Soul-Bound Tokens (EIP-5192), and modular compliance.

## High-Level Architecture

```
                                      +-------------------+
                                      |       User        |
                                      |    (Investor)     |
                                      +---------+---------+
                                                |
                                                v
+-----------------------------------------------------------------------------+
|                              FRONTEND LAYER                                  |
|  +--------------+  +--------------+  +--------------+  +-----------------+  |
|  |  Credential  |  | Verification |  |  Investment  |  |    Portfolio    |  |
|  |     Card     |  |     Flow     |  |     Pools    |  |    Dashboard    |  |
|  +--------------+  +--------------+  +--------------+  +-----------------+  |
|                                                                              |
|  +------------------------------------------------------------------------+  |
|  |                  ZK Proof Generation (Client-Side)                     |  |
|  |   User Data --> SP1 Circuit --> Proof --> On-chain Verification        |  |
|  +------------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------+
                                                |
                                                v
+-----------------------------------------------------------------------------+
|                           SMART CONTRACT LAYER                               |
|                                                                              |
|  +------------------------------------------------------------------------+  |
|  |                  ERC-3643 T-REX Identity System                        |  |
|  |  +------------------+  +------------------+  +----------------------+  |  |
|  |  | IdentityRegistry |  | ClaimTopics      |  | TrustedIssuers       |  |  |
|  |  |                  |  | Registry         |  | Registry             |  |  |
|  |  +------------------+  +------------------+  +----------------------+  |  |
|  +------------------------------------------------------------------------+  |
|                                                                              |
|  +------------------------------------------------------------------------+  |
|  |                    Compliance & Token Layer                            |  |
|  |  +------------------+  +------------------+  +----------------------+  |  |
|  |  |ModularCompliance |  |   VerifiToken    |  |  ComplianceModules   |  |  |
|  |  |                  |  |   (ERC-3643)     |  | (Country/Accredited) |  |  |
|  |  +------------------+  +------------------+  +----------------------+  |  |
|  +------------------------------------------------------------------------+  |
|                                                                              |
|  +------------------------------------------------------------------------+  |
|  |                   Verification & Credentials                           |  |
|  |  +------------------+  +----------------------------------------------+  |
|  |  | SP1Credential    |  |            CredentialSBT                     |  |
|  |  | Verifier         |  |            (EIP-5192)                        |  |
|  |  | (ZK Proofs)      |  |       Non-transferable Credentials           |  |
|  |  +------------------+  +----------------------------------------------+  |
|  +------------------------------------------------------------------------+  |
|                                                                              |
|  +------------------------------------------------------------------------+  |
|  |                       RWA Investment Layer                             |  |
|  |  +------------------------------+  +--------------------------------+  |  |
|  |  |           RWAGate            |  |           RWAPool              |  |  |
|  |  |     (Credential Gating)      |  |      (Investment Pools)        |  |  |
|  |  +------------------------------+  +--------------------------------+  |  |
|  +------------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------+
```

## ERC-3643 T-REX Protocol Implementation

```
                            +------------------------+
                            |      VerifiToken       |
                            |       (ERC-3643)       |
                            |                        |
                            | - transfer()           |
                            | - transferFrom()       |
                            | - mint()               |
                            | - burn()               |
                            +-----------+------------+
                                        |
                                        | checks
                                        v
            +--------------------------------------------------+
            |                                                  |
            v                                                  v
+------------------------+                      +------------------------+
|   IdentityRegistry     |                      |   ModularCompliance    |
|                        |                      |                        |
| - isVerified()         |                      | - canTransfer()        |
| - identity()           |                      | - transferred()        |
| - investorCountry()    |                      | - bindToken()          |
+-----------+------------+                      +-----------+------------+
            |                                               |
            v                                               v
+------------------------+                      +------------------------+
| IdentityRegistry       |                      |   Compliance Modules   |
|      Storage           |                      |                        |
|                        |                      | +--------------------+ |
| - linkedIdentity[]     |                      | | CountryRestrict    | |
| - identityCountry[]    |                      | | Module             | |
| - investorList         |                      | +--------------------+ |
+------------------------+                      | +--------------------+ |
                                                | | AccreditedInvestor | |
+------------------------+                      | | Module             | |
| ClaimTopicsRegistry    |                      | +--------------------+ |
|                        |                      +------------------------+
| - requiredClaimTopics  |
| - getClaimTopics()     |
+------------------------+

+------------------------+
| TrustedIssuersRegistry |
|                        |
| - trustedIssuers[]     |
| - isTrustedIssuer()    |
| - claimTopics()        |
+------------------------+
```

## Zero-Knowledge Proof Flow (SP1)

```
     Private Data                 ZK Circuit                   On-chain
          |                          |                            |
          v                          v                            v
+------------------+         +------------------+         +------------------+
|  User's KYC Data |         |    SP1 Program   |         |  SP1Credential   |
|                  |         |      (Rust)      |         |    Verifier      |
| - Name           |  --->   |                  |  --->   |                  |
| - Date of Birth  |         | Verify:          |         | verifyProof()    |
| - Country        |         | - Signatures     |         | verifyAndMint()  |
| - Accreditation  |         | - Expiration     |         |                  |
|                  |         | - Claim Types    |         | if valid:        |
| (Never exposed)  |         |                  |         |   mint SBT       |
+------------------+         +------------------+         +------------------+
                                    |
                                    v
                            +------------------+
                            |     Output:      |
                            |                  |
                            | - proof (bytes)  |
                            | - publicInputs   |
                            |   - credential   |
                            |     type         |
                            |   - user addr    |
                            |   - timestamp    |
                            +------------------+

+----------------------------------------------------------------------+
|                          CREDENTIAL TYPES                             |
+------+------------------------+--------------------------------------+
|  ID  | Type                   | Description                          |
+------+------------------------+--------------------------------------+
|   1  | KYC                    | Basic identity verification          |
|   2  | Accredited Investor    | SEC accredited ($1M+ or $200K+)      |
|   3  | Qualified Purchaser    | SEC qualified ($5M+ investments)     |
|   4  | Institutional          | Institutional investor status        |
|   5  | AML                    | Anti-money laundering verification   |
+------+------------------------+--------------------------------------+
```

## Soul-Bound Token (EIP-5192) Architecture

```
                         +------------------------+
                         |     CredentialSBT      |
                         |   (Non-Transferable)   |
                         +-----------+------------+
                                     |
         +---------------------------+---------------------------+
         |                           |                           |
         v                           v                           v
+--------------------+     +--------------------+     +--------------------+
|   Credential #1    |     |   Credential #2    |     |   Credential #3    |
|                    |     |                    |     |                    |
|  Type: KYC         |     |  Type: Accredited  |     |  Type: AML         |
|  Issuer: 0x...     |     |  Issuer: 0x...     |     |  Issuer: 0x...     |
|  Issued: Jan 2026  |     |  Issued: Jan 2026  |     |  Issued: Jan 2026  |
|  Expires: Jan 2027 |     |  Expires: Jan 2027 |     |  Expires: Jan 2027 |
|                    |     |                    |     |                    |
|  locked() = true   |     |  locked() = true   |     |  locked() = true   |
|  [No Transfer]     |     |  [No Transfer]     |     |  [No Transfer]     |
+--------------------+     +--------------------+     +--------------------+

     +----------------------------------------------------------------------+
     |                         SBT PROPERTIES                                |
     +----------------------------------------------------------------------+
     |  [x] Non-Transferable: Tokens are permanently bound to the wallet    |
     |  [x] Revocable: Issuer can revoke credentials if needed              |
     |  [x] Expirable: Credentials have expiration dates                    |
     |  [x] Verifiable: Anyone can check credential validity on-chain       |
     |  [x] Privacy-Preserving: No personal data stored on-chain            |
     +----------------------------------------------------------------------+
```

## RWA Investment Flow

```
     Investor                    RWAGate                       RWAPool
         |                          |                             |
         |    1. Request Access     |                             |
         | -----------------------> |                             |
         |                          |                             |
         |                          |  2. Check Credentials       |
         |                          |  +---------------------+    |
         |                          |  | CredentialSBT.has() |    |
         |                          |  | - KYC [x]           |    |
         |                          |  | - Accredited [x]    |    |
         |                          |  | - AML [x]           |    |
         |                          |  +---------------------+    |
         |                          |                             |
         |   3. Access Granted      |                             |
         | <----------------------- |                             |
         |                          |                             |
         |              4. Invest Tokens                          |
         | -----------------------------------------------------> |
         |                          |                             |
         |                          |     5. Compliance Check     |
         |                          | <-------------------------- |
         |                          |                             |
         |                          |  6. Verify Identity         |
         |                          |  +---------------------+    |
         |                          |  | IdentityRegistry    |    |
         |                          |  | .isVerified() [x]   |    |
         |                          |  +---------------------+    |
         |                          |                             |
         |                          |  7. Check Compliance        |
         |                          |  +---------------------+    |
         |                          |  | ModularCompliance   |    |
         |                          |  | .canTransfer() [x]  |    |
         |                          |  +---------------------+    |
         |                          |                             |
         |              8. Investment Confirmed                   |
         | <----------------------------------------------------- |
         |                          |                             |

     +----------------------------------------------------------------------+
     |                       INVESTMENT POOL TYPES                           |
     +----------------------------------------------------------------------+
     |  Real Estate Pool    | Requires: KYC + Accredited Investor           |
     |  Private Equity Pool | Requires: KYC + Qualified Purchaser           |
     |  Treasury Pool       | Requires: KYC + AML                           |
     |  Institutional Pool  | Requires: Institutional Investor Status       |
     +----------------------------------------------------------------------+
```

## Contract Hierarchy

```
                              +------------------+
                              |    Governance    |
                              |   (Owner/Agent)  |
                              +--------+---------+
                                       |
         +-----------------------------+-----------------------------+
         |                             |                             |
         v                             v                             v
+------------------+         +--------------------+       +------------------+
| TrustedIssuers   |         |  IdentityRegistry  |       | ClaimTopics      |
| Registry         |         |                    |       | Registry         |
|                  |         |  +-------------+   |       |                  |
| - addIssuer()    |         |  |  Storage    |   |       | - addTopic()     |
| - removeIssuer() |         |  +-------------+   |       | - removeTopic()  |
| - getIssuers()   |         |                    |       | - getTopics()    |
+------------------+         +--------------------+       +------------------+
                                       |
                                       v
                            +--------------------+
                            |    VerifiToken     |
                            |    (ERC-3643)      |
                            |                    |
                            | - identityRegistry |
                            | - compliance       |
                            +---------+----------+
                                      |
                                      v
                            +--------------------+
                            | ModularCompliance  |
                            |                    |
                            | modules[]:         |
                            | - CountryRestrict  |
                            | - AccreditedOnly   |
                            +--------------------+

+----------------------------------------------------------------------+
|                       VERIFICATION LAYER                              |
+----------------------------------------------------------------------+
|                                                                       |
|   +--------------------+                  +------------------------+  |
|   | SP1Credential      | ---verifies--->  |     CredentialSBT      |  |
|   | Verifier           |                  |       (EIP-5192)       |  |
|   |                    |                  |                        |  |
|   | - verifyProof()    |                  | - mintCredential()     |  |
|   | - verifyAndMint()  |                  | - getCredential()      |  |
|   |                    |                  | - revokeCredential()   |  |
|   +--------------------+                  +------------------------+  |
|                                                                       |
+----------------------------------------------------------------------+

+----------------------------------------------------------------------+
|                      RWA INVESTMENT LAYER                             |
+----------------------------------------------------------------------+
|                                                                       |
|   +--------------------+                  +------------------------+  |
|   |      RWAGate       | -----gates-----> |        RWAPool         |  |
|   |                    |                  |                        |  |
|   | - checkAccess()    |                  | - deposit()            |  |
|   | - requiredCreds()  |                  | - withdraw()           |  |
|   |                    |                  | - getBalance()         |  |
|   +--------------------+                  +------------------------+  |
|                                                                       |
+----------------------------------------------------------------------+
```

## Data Flow

```
                    +----------------------------------+
                    |           New Investor           |
                    +-----------------+----------------+
                                      |
                    +-----------------v----------------+
                    |     1. Connect Wallet            |
                    |       (wagmi/RainbowKit)         |
                    +-----------------+----------------+
                                      |
                    +-----------------v----------------+
                    |     2. Submit KYC Information    |
                    |       (Off-chain to issuer)      |
                    +-----------------+----------------+
                                      |
                    +-----------------v----------------+
                    |     3. Generate ZK Proof         |
                    |       (SP1 zkVM - Rust)          |
                    |                                  |
                    |   Private: Name, DOB, etc.       |
                    |   Public: Credential type, addr  |
                    +-----------------+----------------+
                                      |
                    +-----------------v----------------+
                    |     4. Verify & Mint SBT         |
                    |       (SP1CredentialVerifier)    |
                    |                                  |
                    |   --> CredentialSBT.mint()       |
                    +-----------------+----------------+
                                      |
                    +-----------------v----------------+
                    |     5. Register Identity         |
                    |       (IdentityRegistry)         |
                    |                                  |
                    |   wallet --> identity --> claims |
                    +-----------------+----------------+
                                      |
                    +-----------------v----------------+
                    |     6. Access RWA Pools          |
                    |       (RWAGate + RWAPool)        |
                    |                                  |
                    |   Check credentials --> Invest   |
                    +-----------------+----------------+
                                      |
                    +-----------------v----------------+
                    |     7. Trade Security Tokens     |
                    |       (VerifiToken)              |
                    |                                  |
                    |   All transfers verified         |
                    +----------------------------------+
```

## Security Model

```
+----------------------------------------------------------------------+
|                          ACCESS CONTROL                               |
+----------------------------------------------------------------------+
|                                                                       |
|  Role                | Permissions                                    |
|  --------------------+----------------------------------------------  |
|  Token Agent         | Mint/burn tokens, freeze accounts              |
|  Compliance Agent    | Manage compliance modules, update rules        |
|  Registry Agent      | Add/remove identities, manage claims           |
|  Issuer              | Issue/revoke credentials via ZK proofs         |
|  Investor            | Transfer tokens (with compliance), invest      |
|                                                                       |
+----------------------------------------------------------------------+

+----------------------------------------------------------------------+
|                       TRANSFER VALIDATION                             |
+----------------------------------------------------------------------+
|                                                                       |
|  Every transfer() call:                                               |
|                                                                       |
|  1. [x] Sender identity verified in IdentityRegistry                  |
|  2. [x] Receiver identity verified in IdentityRegistry                |
|  3. [x] ModularCompliance.canTransfer() returns true                  |
|  4. [x] Neither party is frozen                                       |
|  5. [x] Token is not paused                                           |
|                                                                       |
|  If ANY check fails --> Transaction reverts                           |
|                                                                       |
+----------------------------------------------------------------------+

+----------------------------------------------------------------------+
|                       PRIVACY GUARANTEES                              |
+----------------------------------------------------------------------+
|                                                                       |
|  [x] Personal data NEVER stored on-chain                              |
|  [x] ZK proofs verify without revealing underlying data               |
|  [x] Only credential type + validity visible on-chain                 |
|  [x] Credential hash enables verification without exposure            |
|  [x] Issuer signatures verified inside ZK circuit                     |
|                                                                       |
+----------------------------------------------------------------------+
```

## Deployed Contracts (Mantle Sepolia)

| Contract | Address | Purpose |
|----------|---------|---------|
| ClaimTopicsRegistry | `0xd59A380EDEC7A7c5b0ec4D383ED9B833121AB7c2` | Required claim topics |
| TrustedIssuersRegistry | `0x524602055273d0484730DC1B8AD7Dd346a5E4d3d` | Trusted credential issuers |
| IdentityRegistryStorage | `0xeA647A33fDd14Fa5cE8D4981A7DF03DbdF1EceCd` | Identity data storage |
| IdentityRegistry | `0xAe5C1B0821e75Cbceca39e4Aa0e5f3691D7340e3` | Wallet-Identity mapping |
| ModularCompliance | `0x49e048Ac1Ab63Cb26B30d14A115d5Ce610116139` | Compliance engine |
| VerifiToken | `0x932029D18aED907867DEa9B468EC4b299e43C0dA` | ERC-3643 security token |
| SP1CredentialVerifier | `0x4335C610aFfdA179b8C1d7e71eA38ff0F54B2F9b` | ZK proof verification |
| CredentialSBT | `0xfaEF33E2f26FdA8581ED46F93936E40D0168b0CB` | Soul-Bound credentials |
| RWAGate | `0x869D70699C93E29A2538558Cd35Ac0997c644414` | Investment access control |
| RWAPool | `0x5611192b09ED58d389ccc186F1ebAf43eFeE11D8` | RWA investment pool |

## Technology Stack

| Layer | Technology |
|-------|------------|
| Frontend | Next.js 14, React 18, TailwindCSS |
| Web3 | wagmi v2, viem |
| ZK Proofs | Succinct SP1 zkVM (Rust) |
| Contracts | Solidity 0.8.24, Hardhat, OpenZeppelin 5.x |
| Standards | ERC-3643 (T-REX), EIP-5192 (Soulbound) |
| Network | Mantle (Chain ID: 5000/5003) |

## Compliance Modules

| Module | Function | Use Case |
|--------|----------|----------|
| CountryRestrictModule | Allowlist/blocklist countries | OFAC sanctions compliance |
| AccreditedInvestorModule | Require accreditation | SEC Reg D offerings |
| QualifiedPurchaserModule | Require QP status | Hedge fund investments |
| MaxHoldersModule | Limit investor count | Rule 506(b) compliance |
| TransferLimitModule | Max transfer size | Risk management |
