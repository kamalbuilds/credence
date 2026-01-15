'use client';

import { useState, useCallback } from 'react';
import { useAccount } from 'wagmi';
import {
  CredentialType,
  CREDENTIAL_TYPE_NAMES,
  CREDENTIAL_TYPE_DESCRIPTIONS,
} from '@/lib/contracts';
import { useVerifiContracts } from '@/hooks/useVerifiContracts';

type VerificationStep = 'select' | 'kyc' | 'proof' | 'mint' | 'complete';

interface VerificationState {
  step: VerificationStep;
  selectedType: CredentialType | null;
  kycData: {
    firstName: string;
    lastName: string;
    dateOfBirth: string;
    country: string;
  } | null;
  proofGenerated: boolean;
  txHash: string | null;
}

export function VerificationFlow() {
  const { address, isConnected } = useAccount();
  const { mintCredential, isLoading: isMinting } = useVerifiContracts();

  const [state, setState] = useState<VerificationState>({
    step: 'select',
    selectedType: null,
    kycData: null,
    proofGenerated: false,
    txHash: null,
  });

  const [isGeneratingProof, setIsGeneratingProof] = useState(false);

  const handleSelectType = (type: CredentialType) => {
    setState((prev) => ({
      ...prev,
      selectedType: type,
      step: 'kyc',
    }));
  };

  const handleKycSubmit = useCallback(
    (data: VerificationState['kycData']) => {
      setState((prev) => ({
        ...prev,
        kycData: data,
        step: 'proof',
      }));
    },
    []
  );

  const handleGenerateProof = async () => {
    setIsGeneratingProof(true);
    // Simulate ZK proof generation
    await new Promise((resolve) => setTimeout(resolve, 3000));
    setState((prev) => ({
      ...prev,
      proofGenerated: true,
      step: 'mint',
    }));
    setIsGeneratingProof(false);
  };

  const handleMint = async () => {
    if (!address || state.selectedType === null) return;

    try {
      const txHash = await mintCredential(address, state.selectedType);
      setState((prev) => ({
        ...prev,
        txHash,
        step: 'complete',
      }));
    } catch (error) {
      console.error('Minting failed:', error);
    }
  };

  const resetFlow = () => {
    setState({
      step: 'select',
      selectedType: null,
      kycData: null,
      proofGenerated: false,
      txHash: null,
    });
  };

  if (!isConnected) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-400">Connect your wallet to start verification</p>
      </div>
    );
  }

  return (
    <div className="max-w-2xl mx-auto">
      {/* Progress Steps */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          {(['select', 'kyc', 'proof', 'mint', 'complete'] as const).map((step, index) => {
            const stepIndex = ['select', 'kyc', 'proof', 'mint', 'complete'].indexOf(
              state.step
            );
            const isActive = state.step === step;
            const isCompleted = stepIndex > index;

            return (
              <div key={step} className="flex items-center">
                <div
                  className={`flex items-center justify-center w-10 h-10 rounded-full border-2 transition-colors ${isActive
                      ? 'border-mantle-primary bg-mantle-primary/20 text-mantle-primary'
                      : isCompleted
                        ? 'border-mantle-success bg-mantle-success text-white'
                        : 'border-gray-600 bg-gray-800 text-gray-500'
                    }`}
                >
                  {isCompleted ? (
                    <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                  ) : (
                    <span className="text-sm font-medium">{index + 1}</span>
                  )}
                </div>
                {index < 4 && (
                  <div
                    className={`w-12 sm:w-24 h-0.5 ${isCompleted ? 'bg-mantle-success' : 'bg-gray-700'
                      }`}
                  />
                )}
              </div>
            );
          })}
        </div>
        <div className="flex justify-between mt-2">
          <span className="text-xs text-gray-500">Select</span>
          <span className="text-xs text-gray-500">KYC</span>
          <span className="text-xs text-gray-500">Proof</span>
          <span className="text-xs text-gray-500">Mint</span>
          <span className="text-xs text-gray-500">Done</span>
        </div>
      </div>

      {/* Step Content */}
      <div className="bg-mantle-secondary/30 border border-gray-700 rounded-xl p-6">
        {state.step === 'select' && (
          <SelectCredentialStep onSelect={handleSelectType} />
        )}

        {state.step === 'kyc' && state.selectedType !== null && (
          <KycStep
            credentialType={state.selectedType}
            onSubmit={handleKycSubmit}
            onBack={() => setState((prev) => ({ ...prev, step: 'select' }))}
          />
        )}

        {state.step === 'proof' && (
          <ProofStep
            isGenerating={isGeneratingProof}
            onGenerate={handleGenerateProof}
            onBack={() => setState((prev) => ({ ...prev, step: 'kyc' }))}
          />
        )}

        {state.step === 'mint' && (
          <MintStep
            isMinting={isMinting}
            onMint={handleMint}
            credentialType={state.selectedType!}
          />
        )}

        {state.step === 'complete' && (
          <CompleteStep
            txHash={state.txHash}
            credentialType={state.selectedType!}
            onReset={resetFlow}
          />
        )}
      </div>
    </div>
  );
}

// Step Components
function SelectCredentialStep({
  onSelect,
}: {
  onSelect: (type: CredentialType) => void;
}) {
  const credentialTypes = [
    CredentialType.KYC,
    CredentialType.AccreditedInvestor,
    CredentialType.QualifiedPurchaser,
    CredentialType.InstitutionalInvestor,
    CredentialType.AMLCleared,
  ];

  return (
    <div>
      <h2 className="text-xl font-semibold text-white mb-2">
        Select Credential Type
      </h2>
      <p className="text-gray-400 mb-6">
        Choose the type of credential you want to verify and mint
      </p>

      <div className="space-y-3">
        {credentialTypes.map((type) => (
          <button
            key={type}
            onClick={() => onSelect(type)}
            className="w-full p-4 text-left rounded-lg border border-gray-700 hover:border-mantle-primary/50 hover:bg-mantle-primary/5 transition-all group"
          >
            <div className="flex items-center justify-between">
              <div>
                <h3 className="font-medium text-white group-hover:text-mantle-primary transition-colors">
                  {CREDENTIAL_TYPE_NAMES[type]}
                </h3>
                <p className="text-sm text-gray-500 mt-1">
                  {CREDENTIAL_TYPE_DESCRIPTIONS[type]}
                </p>
              </div>
              <svg
                className="w-5 h-5 text-gray-500 group-hover:text-mantle-primary transition-colors"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}

function KycStep({
  credentialType,
  onSubmit,
  onBack,
}: {
  credentialType: CredentialType;
  onSubmit: (data: VerificationState['kycData']) => void;
  onBack: () => void;
}) {
  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    dateOfBirth: '',
    country: '',
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit(formData);
  };

  return (
    <div>
      <h2 className="text-xl font-semibold text-white mb-2">
        Identity Verification
      </h2>
      <p className="text-gray-400 mb-6">
        Verifying: <span className="text-mantle-primary">{CREDENTIAL_TYPE_NAMES[credentialType]}</span>
      </p>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-400 mb-1">
              First Name
            </label>
            <input
              type="text"
              required
              value={formData.firstName}
              onChange={(e) =>
                setFormData((prev) => ({ ...prev, firstName: e.target.value }))
              }
              className="w-full px-4 py-2 rounded-lg bg-gray-800 border border-gray-700 text-white placeholder-gray-500 focus:outline-none focus:border-mantle-primary"
              placeholder="John"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-400 mb-1">
              Last Name
            </label>
            <input
              type="text"
              required
              value={formData.lastName}
              onChange={(e) =>
                setFormData((prev) => ({ ...prev, lastName: e.target.value }))
              }
              className="w-full px-4 py-2 rounded-lg bg-gray-800 border border-gray-700 text-white placeholder-gray-500 focus:outline-none focus:border-mantle-primary"
              placeholder="Doe"
            />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-400 mb-1">
            Date of Birth
          </label>
          <input
            type="date"
            required
            value={formData.dateOfBirth}
            onChange={(e) =>
              setFormData((prev) => ({ ...prev, dateOfBirth: e.target.value }))
            }
            className="w-full px-4 py-2 rounded-lg bg-gray-800 border border-gray-700 text-white focus:outline-none focus:border-mantle-primary"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-400 mb-1">
            Country
          </label>
          <select
            required
            value={formData.country}
            onChange={(e) =>
              setFormData((prev) => ({ ...prev, country: e.target.value }))
            }
            className="w-full px-4 py-2 rounded-lg bg-gray-800 border border-gray-700 text-white focus:outline-none focus:border-mantle-primary"
          >
            <option value="">Select country</option>
            <option value="US">United States</option>
            <option value="UK">United Kingdom</option>
            <option value="CA">Canada</option>
            <option value="DE">Germany</option>
            <option value="FR">France</option>
            <option value="SG">Singapore</option>
            <option value="JP">Japan</option>
          </select>
        </div>

        {/* <div className="bg-yellow-500/10 border border-yellow-500/30 rounded-lg p-4 mt-4">
          <div className="flex items-start gap-3">
            <svg className="w-5 h-5 text-yellow-500 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
            <div>
              <p className="text-sm text-yellow-200 font-medium">Mock Verification</p>
              <p className="text-xs text-yellow-200/70 mt-1">
                This is a demo. In production, this would connect to a real KYC provider.
              </p>
            </div>
          </div>
        </div> */}

        <div className="flex gap-3 mt-6">
          <button
            type="button"
            onClick={onBack}
            className="px-4 py-2 rounded-lg border border-gray-700 text-gray-400 hover:text-white hover:border-gray-600 transition-colors"
          >
            Back
          </button>
          <button
            type="submit"
            className="flex-1 px-4 py-2 rounded-lg bg-gradient-mantle text-mantle-dark font-semibold hover:opacity-90 transition-opacity"
          >
            Verify Identity
          </button>
        </div>
      </form>
    </div>
  );
}

function ProofStep({
  isGenerating,
  onGenerate,
  onBack,
}: {
  isGenerating: boolean;
  onGenerate: () => void;
  onBack: () => void;
}) {
  return (
    <div className="text-center">
      <h2 className="text-xl font-semibold text-white mb-2">
        Generate ZK Proof
      </h2>
      <p className="text-gray-400 mb-6">
        Create a zero-knowledge proof of your verified identity
      </p>

      <div className="bg-gray-800/50 rounded-xl p-8 mb-6">
        {isGenerating ? (
          <div className="flex flex-col items-center">
            <div className="w-16 h-16 border-4 border-mantle-primary/30 border-t-mantle-primary rounded-full animate-spin mb-4" />
            <p className="text-gray-300">Generating SP1 ZK Proof...</p>
            <p className="text-sm text-gray-500 mt-2">
              This may take a few moments
            </p>
          </div>
        ) : (
          <div className="flex flex-col items-center">
            <svg
              className="w-16 h-16 text-mantle-primary mb-4"
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
            <p className="text-gray-300 mb-2">Ready to generate proof</p>
            <p className="text-sm text-gray-500">
              Your identity data will be proven without revealing personal details
            </p>
          </div>
        )}
      </div>

      <div className="bg-blue-500/10 border border-blue-500/30 rounded-lg p-4 mb-6 text-left">
        <div className="flex items-start gap-3">
          <svg className="w-5 h-5 text-blue-400 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <div>
            <p className="text-sm text-blue-200 font-medium">Privacy Preserved</p>
            <p className="text-xs text-blue-200/70 mt-1">
              SP1 ZK proofs ensure your personal data never leaves your device. Only the proof of verification is stored on-chain.
            </p>
          </div>
        </div>
      </div>

      <div className="flex gap-3">
        <button
          type="button"
          onClick={onBack}
          disabled={isGenerating}
          className="px-4 py-2 rounded-lg border border-gray-700 text-gray-400 hover:text-white hover:border-gray-600 transition-colors disabled:opacity-50"
        >
          Back
        </button>
        <button
          onClick={onGenerate}
          disabled={isGenerating}
          className="flex-1 px-4 py-2 rounded-lg bg-gradient-mantle text-mantle-dark font-semibold hover:opacity-90 transition-opacity disabled:opacity-50"
        >
          {isGenerating ? 'Generating...' : 'Generate Proof'}
        </button>
      </div>
    </div>
  );
}

function MintStep({
  isMinting,
  onMint,
  credentialType,
}: {
  isMinting: boolean;
  onMint: () => void;
  credentialType: CredentialType;
}) {
  return (
    <div className="text-center">
      <h2 className="text-xl font-semibold text-white mb-2">
        Mint Credential SBT
      </h2>
      <p className="text-gray-400 mb-6">
        Mint your verified credential as a Soulbound Token
      </p>

      <div className="bg-gray-800/50 rounded-xl p-6 mb-6">
        <div className="flex items-center justify-center gap-4">
          <div className="p-4 rounded-xl bg-mantle-primary/20">
            <svg className="w-12 h-12 text-mantle-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z" />
            </svg>
          </div>
          <div className="text-left">
            <h3 className="text-lg font-medium text-white">
              {CREDENTIAL_TYPE_NAMES[credentialType]}
            </h3>
            <p className="text-sm text-gray-500">Soulbound Token (Non-transferable)</p>
            <p className="text-sm text-mantle-primary mt-1">Valid for 1 year</p>
          </div>
        </div>
      </div>

      <div className="bg-green-500/10 border border-green-500/30 rounded-lg p-4 mb-6 text-left">
        <div className="flex items-start gap-3">
          <svg className="w-5 h-5 text-green-400 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
          </svg>
          <div>
            <p className="text-sm text-green-200 font-medium">Proof Verified</p>
            <p className="text-xs text-green-200/70 mt-1">
              Your ZK proof has been validated. You can now mint your credential SBT.
            </p>
          </div>
        </div>
      </div>

      <button
        onClick={onMint}
        disabled={isMinting}
        className="w-full px-4 py-3 rounded-lg bg-gradient-mantle text-mantle-dark font-semibold hover:opacity-90 transition-opacity disabled:opacity-50 flex items-center justify-center gap-2"
      >
        {isMinting ? (
          <>
            <div className="w-5 h-5 border-2 border-mantle-dark/30 border-t-mantle-dark rounded-full animate-spin" />
            Minting...
          </>
        ) : (
          <>
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
            </svg>
            Mint Credential SBT
          </>
        )}
      </button>
    </div>
  );
}

function CompleteStep({
  txHash,
  credentialType,
  onReset,
}: {
  txHash: string | null;
  credentialType: CredentialType;
  onReset: () => void;
}) {
  return (
    <div className="text-center">
      <div className="w-20 h-20 mx-auto mb-6 rounded-full bg-mantle-success/20 flex items-center justify-center animate-pulse-glow">
        <svg className="w-10 h-10 text-mantle-success" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
        </svg>
      </div>

      <h2 className="text-2xl font-bold text-white mb-2">
        Credential Minted!
      </h2>
      <p className="text-gray-400 mb-6">
        Your <span className="text-mantle-primary">{CREDENTIAL_TYPE_NAMES[credentialType]}</span> credential has been successfully minted
      </p>

      {txHash && (
        <div className="bg-gray-800/50 rounded-lg p-4 mb-6">
          <p className="text-sm text-gray-500 mb-1">Transaction Hash</p>
          <a
            href={`https://explorer.sepolia.mantle.xyz/tx/${txHash}`}
            target="_blank"
            rel="noopener noreferrer"
            className="text-mantle-primary hover:text-mantle-accent font-mono text-sm break-all"
          >
            {txHash}
          </a>
        </div>
      )}

      <div className="flex gap-3">
        <button
          onClick={onReset}
          className="flex-1 px-4 py-2 rounded-lg border border-gray-700 text-gray-400 hover:text-white hover:border-gray-600 transition-colors"
        >
          Get Another Credential
        </button>
        <a
          href="#credentials"
          className="flex-1 px-4 py-2 rounded-lg bg-gradient-mantle text-mantle-dark font-semibold hover:opacity-90 transition-opacity text-center"
        >
          View My Credentials
        </a>
      </div>
    </div>
  );
}
