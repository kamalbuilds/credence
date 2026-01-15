// Contract addresses on Mantle Sepolia (Chain ID 5003)
// Deployed: 2026-01-15

// Core Credence Protocol Contracts
export const CONTRACT_ADDRESSES = {
  // ERC-3643 T-REX Identity & Compliance Infrastructure
  ClaimTopicsRegistry: '0xd59A380EDEC7A7c5b0ec4D383ED9B833121AB7c2' as `0x${string}`,
  TrustedIssuersRegistry: '0x524602055273d0484730DC1B8AD7Dd346a5E4d3d' as `0x${string}`,
  IdentityRegistryStorage: '0xeA647A33fDd14Fa5cE8D4981A7DF03DbdF1EceCd' as `0x${string}`,
  IdentityRegistry: '0xAe5C1B0821e75Cbceca39e4Aa0e5f3691D7340e3' as `0x${string}`,
  ModularCompliance: '0x49e048Ac1Ab63Cb26B30d14A115d5Ce610116139' as `0x${string}`,

  // Security Token (ERC-3643 Compliant)
  VerifiToken: '0x932029D18aED907867DEa9B468EC4b299e43C0dA' as `0x${string}`,

  // SP1 ZK Proof Verification
  SP1CredentialVerifier: '0x4335C610aFfdA179b8C1d7e71eA38ff0F54B2F9b' as `0x${string}`,

  // Soul-Bound Token Credentials (EIP-5192)
  CredentialSBT: '0xfaEF33E2f26FdA8581ED46F93936E40D0168b0CB' as `0x${string}`,

  // RWA Investment Infrastructure
  RWAGate: '0x869D70699C93E29A2538558Cd35Ac0997c644414' as `0x${string}`,
  RWAPool: '0x5611192b09ED58d389ccc186F1ebAf43eFeE11D8' as `0x${string}`,
} as const;

// Network Configuration
export const MANTLE_SEPOLIA_CONFIG = {
  chainId: 5003,
  name: 'Mantle Sepolia Testnet',
  rpcUrl: 'https://rpc.sepolia.mantle.xyz',
  explorerUrl: 'https://sepolia.mantlescan.xyz',
  nativeCurrency: {
    name: 'MNT',
    symbol: 'MNT',
    decimals: 18,
  },
} as const;

// Credential types
export enum CredentialType {
  KYC = 0,
  AccreditedInvestor = 1,
  QualifiedPurchaser = 2,
  InstitutionalInvestor = 3,
  AMLCleared = 4,
}

export const CREDENTIAL_TYPE_NAMES: Record<CredentialType, string> = {
  [CredentialType.KYC]: 'KYC Verified',
  [CredentialType.AccreditedInvestor]: 'Accredited Investor',
  [CredentialType.QualifiedPurchaser]: 'Qualified Purchaser',
  [CredentialType.InstitutionalInvestor]: 'Institutional Investor',
  [CredentialType.AMLCleared]: 'AML Cleared',
};

export const CREDENTIAL_TYPE_DESCRIPTIONS: Record<CredentialType, string> = {
  [CredentialType.KYC]: 'Basic identity verification for platform access',
  [CredentialType.AccreditedInvestor]: 'SEC-defined accredited investor status ($1M+ net worth or $200K+ income)',
  [CredentialType.QualifiedPurchaser]: 'Higher tier investor status ($5M+ in investments)',
  [CredentialType.InstitutionalInvestor]: 'Institutional entity verification',
  [CredentialType.AMLCleared]: 'Anti-money laundering compliance check',
};

// ABIs for contract interactions
export const CREDENTIAL_SBT_ABI = [
  {
    inputs: [{ name: 'owner', type: 'address' }],
    name: 'balanceOf',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'tokenId', type: 'uint256' }],
    name: 'getCredential',
    outputs: [
      {
        components: [
          { name: 'credentialType', type: 'uint8' },
          { name: 'issuer', type: 'address' },
          { name: 'issuedAt', type: 'uint256' },
          { name: 'expiresAt', type: 'uint256' },
          { name: 'credentialHash', type: 'bytes32' },
          { name: 'isValid', type: 'bool' },
        ],
        name: '',
        type: 'tuple',
      },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'owner', type: 'address' }],
    name: 'getCredentialsByOwner',
    outputs: [{ name: '', type: 'uint256[]' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [
      { name: 'to', type: 'address' },
      { name: 'credentialType', type: 'uint8' },
      { name: 'expiresAt', type: 'uint256' },
      { name: 'credentialHash', type: 'bytes32' },
    ],
    name: 'mintCredential',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, name: 'tokenId', type: 'uint256' },
      { indexed: true, name: 'owner', type: 'address' },
      { indexed: false, name: 'credentialType', type: 'uint8' },
    ],
    name: 'CredentialMinted',
    type: 'event',
  },
] as const;

export const SP1_VERIFIER_ABI = [
  {
    inputs: [
      { name: 'proof', type: 'bytes' },
      { name: 'publicInputs', type: 'bytes32[]' },
    ],
    name: 'verifyProof',
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [
      { name: 'proof', type: 'bytes' },
      { name: 'publicInputs', type: 'bytes32[]' },
      { name: 'to', type: 'address' },
      { name: 'credentialType', type: 'uint8' },
    ],
    name: 'verifyAndMint',
    outputs: [{ name: 'tokenId', type: 'uint256' }],
    stateMutability: 'nonpayable',
    type: 'function',
  },
] as const;

export const IDENTITY_REGISTRY_ABI = [
  {
    inputs: [
      { name: 'user', type: 'address' },
      { name: 'credentialType', type: 'uint8' },
    ],
    name: 'hasValidCredential',
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'user', type: 'address' }],
    name: 'getUserCredentials',
    outputs: [{ name: '', type: 'uint8[]' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [
      { name: 'user', type: 'address' },
      { name: 'requiredCredentials', type: 'uint8[]' },
    ],
    name: 'checkAccess',
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'view',
    type: 'function',
  },
] as const;
