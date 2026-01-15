'use client';

import { useAccount, useConnect, useDisconnect, useChainId, useSwitchChain } from 'wagmi';
import { injected } from 'wagmi/connectors';
import { mantleSepolia } from '@/app/providers';

export function ConnectButton() {
  const { address, isConnected } = useAccount();
  const { connect, isPending: isConnecting } = useConnect();
  const { disconnect } = useDisconnect();
  const chainId = useChainId();
  const { switchChain } = useSwitchChain();

  const isWrongNetwork = isConnected && chainId !== mantleSepolia.id;

  const handleConnect = () => {
    connect({ connector: injected() });
  };

  const handleSwitchNetwork = () => {
    switchChain({ chainId: mantleSepolia.id });
  };

  if (isConnected && address) {
    return (
      <div className="flex items-center gap-4">
        {isWrongNetwork ? (
          <button
            onClick={handleSwitchNetwork}
            className="px-4 py-2 bg-mantle-warning text-mantle-dark font-semibold rounded-lg hover:bg-yellow-400 transition-colors"
          >
            Switch to Mantle Sepolia
          </button>
        ) : (
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 bg-mantle-success rounded-full animate-pulse" />
            <span className="text-sm text-gray-400">Mantle Sepolia</span>
          </div>
        )}
        <div className="flex items-center gap-3 px-4 py-2 bg-mantle-secondary/50 border border-mantle-primary/20 rounded-lg">
          <span className="text-sm font-mono text-gray-300">
            {address.slice(0, 6)}...{address.slice(-4)}
          </span>
          <button
            onClick={() => disconnect()}
            className="text-xs text-mantle-error hover:text-red-400 transition-colors"
          >
            Disconnect
          </button>
        </div>
      </div>
    );
  }

  return (
    <button
      onClick={handleConnect}
      disabled={isConnecting}
      className="px-6 py-3 bg-gradient-mantle text-mantle-dark font-bold rounded-lg hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed"
    >
      {isConnecting ? 'Connecting...' : 'Connect Wallet'}
    </button>
  );
}
