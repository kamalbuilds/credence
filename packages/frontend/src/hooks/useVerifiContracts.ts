'use client';

import { useState, useCallback } from 'react';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { keccak256, toBytes, encodePacked } from 'viem';
import {
  CONTRACT_ADDRESSES,
  CREDENTIAL_SBT_ABI,
  SP1_VERIFIER_ABI,
  IDENTITY_REGISTRY_ABI,
  CredentialType,
} from '@/lib/contracts';

interface Credential {
  tokenId: bigint;
  credentialType: CredentialType;
  issuer: string;
  issuedAt: bigint;
  expiresAt: bigint;
  credentialHash: string;
  isValid: boolean;
}

export function useVerifiContracts() {
  const { address } = useAccount();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const { writeContractAsync } = useWriteContract();

  // Get user's credential token IDs
  const { data: credentialTokenIds, refetch: refetchCredentials } = useReadContract({
    address: CONTRACT_ADDRESSES.CredentialSBT,
    abi: CREDENTIAL_SBT_ABI,
    functionName: 'getCredentialsByOwner',
    args: address ? [address] : undefined,
    query: {
      enabled: !!address,
    },
  });

  // Check if user has a specific credential type
  const checkCredential = useCallback(
    async (credentialType: CredentialType): Promise<boolean> => {
      if (!address) return false;

      try {
        // In production, this would call the IdentityRegistry contract
        // For now, we'll simulate based on mock data
        return false;
      } catch (err) {
        console.error('Error checking credential:', err);
        return false;
      }
    },
    [address]
  );

  // Generate a mock ZK proof
  const generateProof = useCallback(
    async (
      credentialType: CredentialType,
      kycData: { firstName: string; lastName: string; dateOfBirth: string; country: string }
    ): Promise<{ proof: `0x${string}`; publicInputs: `0x${string}`[] }> => {
      // Simulate proof generation delay
      await new Promise((resolve) => setTimeout(resolve, 2000));

      // Create mock proof data
      // In production, this would call an SP1 prover to generate a real ZK proof
      const mockProofData = encodePacked(
        ['string', 'string', 'string', 'string', 'uint8'],
        [kycData.firstName, kycData.lastName, kycData.dateOfBirth, kycData.country, credentialType]
      );

      const proof = keccak256(mockProofData) as `0x${string}`;
      const publicInputHash = keccak256(
        encodePacked(['address', 'uint8', 'uint256'], [address!, credentialType, BigInt(Date.now())])
      ) as `0x${string}`;

      return {
        proof: `0x${proof.slice(2).repeat(8)}` as `0x${string}`, // Simulate longer proof
        publicInputs: [publicInputHash],
      };
    },
    [address]
  );

  // Mint a credential SBT
  const mintCredential = useCallback(
    async (to: `0x${string}`, credentialType: CredentialType): Promise<string> => {
      setIsLoading(true);
      setError(null);

      try {
        // Generate expiration timestamp (1 year from now)
        const expiresAt = BigInt(Math.floor(Date.now() / 1000) + 365 * 24 * 60 * 60);

        // Generate credential hash
        const credentialHash = keccak256(
          encodePacked(
            ['address', 'uint8', 'uint256'],
            [to, credentialType, BigInt(Date.now())]
          )
        ) as `0x${string}`;

        // For demo purposes, we'll simulate the transaction
        // In production, this would verify the ZK proof first via SP1CredentialVerifier
        const txHash = await writeContractAsync({
          address: CONTRACT_ADDRESSES.CredentialSBT,
          abi: CREDENTIAL_SBT_ABI,
          functionName: 'mintCredential',
          args: [to, credentialType, expiresAt, credentialHash],
        });

        // Refetch credentials after minting
        await refetchCredentials();

        return txHash;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to mint credential');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [writeContractAsync, refetchCredentials]
  );

  // Verify and mint in one transaction (using SP1 verifier)
  const verifyAndMint = useCallback(
    async (
      proof: `0x${string}`,
      publicInputs: `0x${string}`[],
      credentialType: CredentialType
    ): Promise<string> => {
      if (!address) throw new Error('Wallet not connected');

      setIsLoading(true);
      setError(null);

      try {
        const txHash = await writeContractAsync({
          address: CONTRACT_ADDRESSES.SP1CredentialVerifier,
          abi: SP1_VERIFIER_ABI,
          functionName: 'verifyAndMint',
          args: [proof, publicInputs, address, credentialType],
        });

        await refetchCredentials();
        return txHash;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to verify and mint');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [address, writeContractAsync, refetchCredentials]
  );

  return {
    credentialTokenIds: credentialTokenIds as bigint[] | undefined,
    isLoading,
    error,
    checkCredential,
    generateProof,
    mintCredential,
    verifyAndMint,
    refetchCredentials,
  };
}

// Hook for fetching individual credential details
export function useCredential(tokenId: bigint | undefined) {
  const { data, isLoading, error } = useReadContract({
    address: CONTRACT_ADDRESSES.CredentialSBT,
    abi: CREDENTIAL_SBT_ABI,
    functionName: 'getCredential',
    args: tokenId !== undefined ? [tokenId] : undefined,
    query: {
      enabled: tokenId !== undefined,
    },
  });

  const credential: Credential | undefined = data
    ? {
        tokenId: tokenId!,
        credentialType: (data as any).credentialType,
        issuer: (data as any).issuer,
        issuedAt: (data as any).issuedAt,
        expiresAt: (data as any).expiresAt,
        credentialHash: (data as any).credentialHash,
        isValid: (data as any).isValid,
      }
    : undefined;

  return {
    credential,
    isLoading,
    error,
  };
}

// Hook for checking access to a pool
export function useAccessCheck(requiredCredentials: CredentialType[]) {
  const { address } = useAccount();

  const { data: hasAccess, isLoading } = useReadContract({
    address: CONTRACT_ADDRESSES.IdentityRegistry,
    abi: IDENTITY_REGISTRY_ABI,
    functionName: 'checkAccess',
    args: address ? [address, requiredCredentials] : undefined,
    query: {
      enabled: !!address && requiredCredentials.length > 0,
    },
  });

  return {
    hasAccess: hasAccess as boolean | undefined,
    isLoading,
  };
}
