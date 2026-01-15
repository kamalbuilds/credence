'use client';

import { useState } from 'react';
import { useAccount } from 'wagmi';
import { CredentialType, CREDENTIAL_TYPE_NAMES } from '@/lib/contracts';

interface InvestmentPool {
  id: string;
  name: string;
  description: string;
  assetType: string;
  apy: string;
  tvl: string;
  minInvestment: string;
  requiredCredentials: CredentialType[];
  riskLevel: 'low' | 'medium' | 'high';
  status: 'open' | 'closed' | 'coming_soon';
}

const MOCK_POOLS: InvestmentPool[] = [
  {
    id: '1',
    name: 'Mantle Real Estate Fund I',
    description: 'Diversified portfolio of commercial real estate properties across major US markets',
    assetType: 'Commercial Real Estate',
    apy: '8.5%',
    tvl: '$12.5M',
    minInvestment: '$10,000',
    requiredCredentials: [CredentialType.KYC, CredentialType.AccreditedInvestor],
    riskLevel: 'medium',
    status: 'open',
  },
  {
    id: '2',
    name: 'Treasury Bond Yield Token',
    description: 'Tokenized exposure to US Treasury bonds with automatic yield distribution',
    assetType: 'Government Bonds',
    apy: '4.2%',
    tvl: '$45.8M',
    minInvestment: '$1,000',
    requiredCredentials: [CredentialType.KYC],
    riskLevel: 'low',
    status: 'open',
  },
  {
    id: '3',
    name: 'Private Credit Fund',
    description: 'Senior secured loans to mid-market companies with strong cash flows',
    assetType: 'Private Credit',
    apy: '12.0%',
    tvl: '$8.2M',
    minInvestment: '$50,000',
    requiredCredentials: [CredentialType.KYC, CredentialType.QualifiedPurchaser],
    riskLevel: 'high',
    status: 'open',
  },
  {
    id: '4',
    name: 'Infrastructure Income Fund',
    description: 'Sustainable infrastructure projects including solar, wind, and data centers',
    assetType: 'Infrastructure',
    apy: '7.8%',
    tvl: '$22.1M',
    minInvestment: '$25,000',
    requiredCredentials: [CredentialType.KYC, CredentialType.AccreditedInvestor, CredentialType.AMLCleared],
    riskLevel: 'medium',
    status: 'open',
  },
  {
    id: '5',
    name: 'Institutional Grade Real Assets',
    description: 'Exclusive access to institutional-quality alternative investments',
    assetType: 'Multi-Asset',
    apy: '15.0%',
    tvl: '$150M',
    minInvestment: '$500,000',
    requiredCredentials: [CredentialType.KYC, CredentialType.InstitutionalInvestor],
    riskLevel: 'high',
    status: 'coming_soon',
  },
];

interface InvestmentPoolsProps {
  userCredentials: CredentialType[];
}

export function InvestmentPools({ userCredentials }: InvestmentPoolsProps) {
  const { isConnected } = useAccount();
  const [filter, setFilter] = useState<'all' | 'eligible' | 'locked'>('all');

  const hasRequiredCredentials = (pool: InvestmentPool) => {
    return pool.requiredCredentials.every((cred) => userCredentials.includes(cred));
  };

  const filteredPools = MOCK_POOLS.filter((pool) => {
    if (filter === 'all') return true;
    if (filter === 'eligible') return hasRequiredCredentials(pool);
    if (filter === 'locked') return !hasRequiredCredentials(pool);
    return true;
  });

  const getRiskColor = (risk: InvestmentPool['riskLevel']) => {
    switch (risk) {
      case 'low':
        return 'text-green-400 bg-green-400/10';
      case 'medium':
        return 'text-yellow-400 bg-yellow-400/10';
      case 'high':
        return 'text-red-400 bg-red-400/10';
    }
  };

  const getStatusBadge = (status: InvestmentPool['status']) => {
    switch (status) {
      case 'open':
        return (
          <span className="px-2 py-1 text-xs font-medium rounded-full bg-mantle-success/20 text-mantle-success">
            Open
          </span>
        );
      case 'closed':
        return (
          <span className="px-2 py-1 text-xs font-medium rounded-full bg-gray-500/20 text-gray-400">
            Closed
          </span>
        );
      case 'coming_soon':
        return (
          <span className="px-2 py-1 text-xs font-medium rounded-full bg-blue-500/20 text-blue-400">
            Coming Soon
          </span>
        );
    }
  };

  return (
    <div>
      {/* Header with filters */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
        <div>
          <h2 className="text-xl font-semibold text-white">RWA Investment Pools</h2>
          <p className="text-sm text-gray-400 mt-1">
            Access tokenized real-world assets based on your credentials
          </p>
        </div>

        {isConnected && (
          <div className="flex gap-2">
            {(['all', 'eligible', 'locked'] as const).map((f) => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`px-3 py-1.5 text-sm rounded-lg transition-colors ${
                  filter === f
                    ? 'bg-mantle-primary text-mantle-dark font-medium'
                    : 'bg-gray-800 text-gray-400 hover:text-white'
                }`}
              >
                {f.charAt(0).toUpperCase() + f.slice(1)}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Pool grid */}
      <div className="grid gap-4 md:grid-cols-2">
        {filteredPools.map((pool) => {
          const isEligible = hasRequiredCredentials(pool);
          const missingCredentials = pool.requiredCredentials.filter(
            (cred) => !userCredentials.includes(cred)
          );

          return (
            <div
              key={pool.id}
              className={`relative rounded-xl border p-6 transition-all ${
                isEligible
                  ? 'border-gray-700 bg-mantle-secondary/30 hover:border-mantle-primary/50'
                  : 'border-gray-800 bg-gray-900/30 opacity-75'
              }`}
            >
              {/* Lock overlay for ineligible pools */}
              {!isEligible && isConnected && (
                <div className="absolute inset-0 bg-gray-900/50 rounded-xl flex items-center justify-center backdrop-blur-sm z-10">
                  <div className="text-center px-4">
                    <svg
                      className="w-8 h-8 text-gray-500 mx-auto mb-2"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                      />
                    </svg>
                    <p className="text-sm text-gray-400 mb-1">Missing credentials:</p>
                    <div className="flex flex-wrap gap-1 justify-center">
                      {missingCredentials.map((cred) => (
                        <span
                          key={cred}
                          className="text-xs px-2 py-0.5 rounded bg-gray-800 text-gray-300"
                        >
                          {CREDENTIAL_TYPE_NAMES[cred]}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>
              )}

              {/* Pool header */}
              <div className="flex items-start justify-between mb-4">
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <h3 className="text-lg font-semibold text-white">{pool.name}</h3>
                    {getStatusBadge(pool.status)}
                  </div>
                  <p className="text-sm text-gray-500">{pool.assetType}</p>
                </div>
                <span
                  className={`px-2 py-1 text-xs font-medium rounded ${getRiskColor(
                    pool.riskLevel
                  )}`}
                >
                  {pool.riskLevel.toUpperCase()}
                </span>
              </div>

              {/* Description */}
              <p className="text-sm text-gray-400 mb-4 line-clamp-2">{pool.description}</p>

              {/* Stats grid */}
              <div className="grid grid-cols-3 gap-4 mb-4">
                <div>
                  <p className="text-xs text-gray-500">APY</p>
                  <p className="text-lg font-semibold text-mantle-primary">{pool.apy}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500">TVL</p>
                  <p className="text-lg font-semibold text-white">{pool.tvl}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500">Min. Investment</p>
                  <p className="text-lg font-semibold text-white">{pool.minInvestment}</p>
                </div>
              </div>

              {/* Required credentials */}
              <div className="border-t border-gray-700/50 pt-4">
                <p className="text-xs text-gray-500 mb-2">Required Credentials</p>
                <div className="flex flex-wrap gap-2">
                  {pool.requiredCredentials.map((cred) => {
                    const hasCredential = userCredentials.includes(cred);
                    return (
                      <span
                        key={cred}
                        className={`inline-flex items-center gap-1 text-xs px-2 py-1 rounded ${
                          hasCredential
                            ? 'bg-mantle-success/20 text-mantle-success'
                            : 'bg-gray-800 text-gray-400'
                        }`}
                      >
                        {hasCredential && (
                          <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                          </svg>
                        )}
                        {CREDENTIAL_TYPE_NAMES[cred]}
                      </span>
                    );
                  })}
                </div>
              </div>

              {/* Action button */}
              {isEligible && pool.status === 'open' && (
                <button className="w-full mt-4 px-4 py-2 rounded-lg bg-gradient-mantle text-mantle-dark font-semibold hover:opacity-90 transition-opacity">
                  Invest Now
                </button>
              )}
            </div>
          );
        })}
      </div>

      {filteredPools.length === 0 && (
        <div className="text-center py-12 bg-gray-900/30 rounded-xl border border-gray-800">
          <svg
            className="w-12 h-12 text-gray-600 mx-auto mb-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={1.5}
              d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          <p className="text-gray-400">No pools match your current filter</p>
        </div>
      )}
    </div>
  );
}
