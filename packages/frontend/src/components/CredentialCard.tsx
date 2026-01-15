'use client';

import {
  CredentialType,
  CREDENTIAL_TYPE_NAMES,
  CREDENTIAL_TYPE_DESCRIPTIONS,
} from '@/lib/contracts';

interface Credential {
  tokenId: bigint;
  credentialType: CredentialType;
  issuer: string;
  issuedAt: bigint;
  expiresAt: bigint;
  isValid: boolean;
}

interface CredentialCardProps {
  credential: Credential;
}

export function CredentialCard({ credential }: CredentialCardProps) {
  const isExpired = Date.now() > Number(credential.expiresAt) * 1000;
  const isActive = credential.isValid && !isExpired;

  const formatDate = (timestamp: bigint) => {
    return new Date(Number(timestamp) * 1000).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  const getStatusColor = () => {
    if (!credential.isValid) return 'bg-mantle-error';
    if (isExpired) return 'bg-mantle-warning';
    return 'bg-mantle-success';
  };

  const getStatusText = () => {
    if (!credential.isValid) return 'Revoked';
    if (isExpired) return 'Expired';
    return 'Active';
  };

  const getCredentialIcon = () => {
    switch (credential.credentialType) {
      case CredentialType.KYC:
        return (
          <svg className="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
          </svg>
        );
      case CredentialType.AccreditedInvestor:
        return (
          <svg className="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        );
      case CredentialType.QualifiedPurchaser:
        return (
          <svg className="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z" />
          </svg>
        );
      case CredentialType.InstitutionalInvestor:
        return (
          <svg className="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
          </svg>
        );
      case CredentialType.AMLCleared:
        return (
          <svg className="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
          </svg>
        );
      default:
        return (
          <svg className="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        );
    }
  };

  return (
    <div
      className={`relative overflow-hidden rounded-xl border ${
        isActive
          ? 'border-mantle-primary/30 bg-mantle-secondary/30'
          : 'border-gray-700/50 bg-gray-900/30'
      } p-6 transition-all hover:border-mantle-primary/50`}
    >
      {/* Status badge */}
      <div className="absolute top-4 right-4">
        <span
          className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${getStatusColor()} text-white`}
        >
          <span className="w-1.5 h-1.5 rounded-full bg-white" />
          {getStatusText()}
        </span>
      </div>

      {/* Credential icon and type */}
      <div className="flex items-start gap-4 mb-4">
        <div
          className={`p-3 rounded-lg ${
            isActive ? 'bg-mantle-primary/20 text-mantle-primary' : 'bg-gray-800 text-gray-500'
          }`}
        >
          {getCredentialIcon()}
        </div>
        <div>
          <h3 className="text-lg font-semibold text-white">
            {CREDENTIAL_TYPE_NAMES[credential.credentialType]}
          </h3>
          <p className="text-sm text-gray-400 mt-1">
            {CREDENTIAL_TYPE_DESCRIPTIONS[credential.credentialType]}
          </p>
        </div>
      </div>

      {/* Credential details */}
      <div className="space-y-2 text-sm">
        <div className="flex justify-between">
          <span className="text-gray-500">Token ID</span>
          <span className="text-gray-300 font-mono">#{credential.tokenId.toString()}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-gray-500">Issued</span>
          <span className="text-gray-300">{formatDate(credential.issuedAt)}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-gray-500">Expires</span>
          <span className={isExpired ? 'text-mantle-warning' : 'text-gray-300'}>
            {formatDate(credential.expiresAt)}
          </span>
        </div>
        <div className="flex justify-between">
          <span className="text-gray-500">Issuer</span>
          <span className="text-gray-300 font-mono text-xs">
            {credential.issuer.slice(0, 6)}...{credential.issuer.slice(-4)}
          </span>
        </div>
      </div>

      {/* SBT indicator */}
      <div className="mt-4 pt-4 border-t border-gray-700/50">
        <div className="flex items-center gap-2 text-xs text-gray-500">
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
          </svg>
          <span>Soulbound Token - Non-transferable</span>
        </div>
      </div>
    </div>
  );
}

// Empty state component
export function CredentialEmptyState() {
  return (
    <div className="flex flex-col items-center justify-center py-12 px-6 rounded-xl border border-dashed border-gray-700 bg-gray-900/20">
      <svg
        className="w-16 h-16 text-gray-600 mb-4"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={1.5}
          d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
        />
      </svg>
      <h3 className="text-lg font-medium text-gray-400 mb-2">No Credentials Yet</h3>
      <p className="text-sm text-gray-500 text-center max-w-sm">
        Complete the verification process to receive your first credential SBT
      </p>
    </div>
  );
}
