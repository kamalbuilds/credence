'use client';

import { useState, useEffect } from 'react';
import { useAccount } from 'wagmi';
import { ConnectButton } from '@/components/ConnectButton';
import { CredentialCard, CredentialEmptyState } from '@/components/CredentialCard';
import { VerificationFlow } from '@/components/VerificationFlow';
import { InvestmentPools } from '@/components/InvestmentPools';
import { CredentialType } from '@/lib/contracts';

// Mock credentials for demo (in production, these would come from the blockchain)
interface MockCredential {
  tokenId: bigint;
  credentialType: CredentialType;
  issuer: string;
  issuedAt: bigint;
  expiresAt: bigint;
  isValid: boolean;
}

export default function Home() {
  const { isConnected, address } = useAccount();
  const [activeTab, setActiveTab] = useState<'verify' | 'credentials' | 'pools'>('verify');
  const [mockCredentials, setMockCredentials] = useState<MockCredential[]>([]);

  // Simulate fetching credentials on connection
  useEffect(() => {
    if (isConnected && address) {
      // For demo purposes, start with empty credentials
      // In production, this would fetch from the blockchain
      setMockCredentials([]);
    } else {
      setMockCredentials([]);
    }
  }, [isConnected, address]);

  // Get user's credential types for pool access checks
  const userCredentialTypes = mockCredentials
    .filter((c) => c.isValid)
    .map((c) => c.credentialType);

  return (
    <div className="min-h-screen">
      {/* Header */}
      <header className="border-b border-gray-800 bg-mantle-dark/80 backdrop-blur-md sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            {/* Logo */}
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-gradient-mantle flex items-center justify-center">
                <svg
                  className="w-6 h-6 text-mantle-dark"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
                  />
                </svg>
              </div>
              <div>
                <h1 className="text-xl font-bold text-white">Credence</h1>
                <p className="text-xs text-gray-500">Privacy-Preserving Credentials</p>
              </div>
            </div>

            {/* Navigation */}
            <nav className="hidden md:flex items-center gap-1">
              {[
                { id: 'verify', label: 'Verify' },
                { id: 'credentials', label: 'My Credentials' },
                { id: 'pools', label: 'Investment Pools' },
              ].map((tab) => (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id as typeof activeTab)}
                  className={`px-4 py-2 text-sm font-medium rounded-lg transition-colors ${activeTab === tab.id
                      ? 'bg-mantle-primary/20 text-mantle-primary'
                      : 'text-gray-400 hover:text-white hover:bg-gray-800'
                    }`}
                >
                  {tab.label}
                </button>
              ))}
            </nav>

            {/* Connect Button */}
            <ConnectButton />
          </div>
        </div>
      </header>

      {/* Mobile Navigation */}
      <div className="md:hidden border-b border-gray-800 bg-mantle-dark/50">
        <div className="flex overflow-x-auto">
          {[
            { id: 'verify', label: 'Verify' },
            { id: 'credentials', label: 'Credentials' },
            { id: 'pools', label: 'Pools' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as typeof activeTab)}
              className={`flex-1 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${activeTab === tab.id
                  ? 'border-mantle-primary text-mantle-primary'
                  : 'border-transparent text-gray-400'
                }`}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Hero Section (only on verify tab) */}
        {activeTab === 'verify' && (
          <div className="text-center mb-12">
            <h2 className="text-3xl sm:text-4xl font-bold text-white mb-4">
              Privacy-Preserving
              <span className="text-transparent bg-clip-text bg-gradient-mantle">
                {' '}
                Credential Verification
              </span>
            </h2>
            <p className="text-gray-400 max-w-2xl mx-auto">
              Verify your identity and investment qualifications using zero-knowledge proofs.
              Your personal data never leaves your device.
            </p>
          </div>
        )}

        {/* Tab Content */}
        {activeTab === 'verify' && (
          <section>
            <VerificationFlow />

            {/* Features Grid */}
            <div className="mt-16 grid md:grid-cols-3 gap-6">
              {[
                {
                  icon: (
                    <svg
                      className="w-8 h-8"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={1.5}
                        d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                      />
                    </svg>
                  ),
                  title: 'Privacy First',
                  description:
                    'Zero-knowledge proofs ensure your personal data is never exposed or stored on-chain.',
                },
                {
                  icon: (
                    <svg
                      className="w-8 h-8"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={1.5}
                        d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
                      />
                    </svg>
                  ),
                  title: 'Soulbound Tokens',
                  description:
                    'Credentials are minted as non-transferable SBTs, ensuring authentic verification.',
                },
                {
                  icon: (
                    <svg
                      className="w-8 h-8"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={1.5}
                        d="M13 10V3L4 14h7v7l9-11h-7z"
                      />
                    </svg>
                  ),
                  title: 'Powered by Mantle',
                  description:
                    'Fast, low-cost transactions on Mantle enable seamless credential management.',
                },
              ].map((feature, index) => (
                <div
                  key={index}
                  className="p-6 rounded-xl border border-gray-800 bg-gray-900/30 hover:border-gray-700 transition-colors"
                >
                  <div className="w-12 h-12 rounded-lg bg-mantle-primary/10 text-mantle-primary flex items-center justify-center mb-4">
                    {feature.icon}
                  </div>
                  <h3 className="text-lg font-semibold text-white mb-2">{feature.title}</h3>
                  <p className="text-sm text-gray-400">{feature.description}</p>
                </div>
              ))}
            </div>
          </section>
        )}

        {activeTab === 'credentials' && (
          <section id="credentials">
            <div className="mb-6">
              <h2 className="text-xl font-semibold text-white">My Credentials</h2>
              <p className="text-sm text-gray-400 mt-1">
                View and manage your verified credential SBTs
              </p>
            </div>

            {!isConnected ? (
              <div className="text-center py-12 bg-gray-900/30 rounded-xl border border-gray-800">
                <svg
                  className="w-16 h-16 text-gray-600 mx-auto mb-4"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={1.5}
                    d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                  />
                </svg>
                <p className="text-gray-400 mb-4">Connect your wallet to view credentials</p>
                <ConnectButton />
              </div>
            ) : mockCredentials.length > 0 ? (
              <div className="grid gap-4 md:grid-cols-2">
                {mockCredentials.map((credential) => (
                  <CredentialCard key={credential.tokenId.toString()} credential={credential} />
                ))}
              </div>
            ) : (
              <CredentialEmptyState />
            )}

            {/* Demo: Add mock credentials button */}
            {isConnected && mockCredentials.length === 0 && (
              <div className="mt-6 p-4 rounded-lg bg-blue-500/10 border border-blue-500/30">
                <div className="flex items-start gap-3">
                  <svg
                    className="w-5 h-5 text-blue-400 mt-0.5"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                  <div>
                    <p className="text-sm text-blue-200 font-medium">Demo Mode</p>
                    <p className="text-xs text-blue-200/70 mt-1">
                      Complete the verification flow to mint your first credential, or{' '}
                      <button
                        onClick={() => {
                          setMockCredentials([
                            {
                              tokenId: BigInt(1),
                              credentialType: CredentialType.KYC,
                              issuer: '0x1234567890123456789012345678901234567890',
                              issuedAt: BigInt(Math.floor(Date.now() / 1000) - 86400),
                              expiresAt: BigInt(Math.floor(Date.now() / 1000) + 365 * 86400),
                              isValid: true,
                            },
                            {
                              tokenId: BigInt(2),
                              credentialType: CredentialType.AccreditedInvestor,
                              issuer: '0x1234567890123456789012345678901234567890',
                              issuedAt: BigInt(Math.floor(Date.now() / 1000) - 86400 * 7),
                              expiresAt: BigInt(Math.floor(Date.now() / 1000) + 365 * 86400),
                              isValid: true,
                            },
                          ]);
                        }}
                        className="text-blue-400 hover:text-blue-300 underline"
                      >
                        add demo credentials
                      </button>
                      .
                    </p>
                  </div>
                </div>
              </div>
            )}
          </section>
        )}

        {activeTab === 'pools' && (
          <section>
            <InvestmentPools userCredentials={userCredentialTypes} />
          </section>
        )}
      </main>

      {/* Footer */}
      <footer className="border-t border-gray-800 mt-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="flex flex-col md:flex-row items-center justify-between gap-4">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-gradient-mantle flex items-center justify-center">
                <svg
                  className="w-5 h-5 text-mantle-dark"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
                  />
                </svg>
              </div>
              <span className="text-sm text-gray-400">
                Credence - Built on Mantle Sepolia
              </span>
            </div>
            <div className="flex items-center gap-6">
              <a
                href="https://docs.mantle.xyz"
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm text-gray-500 hover:text-gray-300 transition-colors"
              >
                Mantle Docs
              </a>
              <a
                href="https://explorer.sepolia.mantle.xyz"
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm text-gray-500 hover:text-gray-300 transition-colors"
              >
                Block Explorer
              </a>
              <a
                href="https://faucet.sepolia.mantle.xyz"
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm text-gray-500 hover:text-gray-300 transition-colors"
              >
                Faucet
              </a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
