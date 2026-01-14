// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "./IIdentityRegistry.sol";
import "./IModularCompliance.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IVerifiToken
 * @notice Interface for ERC-3643 compliant security tokens
 * @dev Extends ERC-20 with identity verification and compliance checking
 */
interface IVerifiToken is IERC20 {
    // Events
    event TokenFrozen(address indexed account);
    event TokenUnfrozen(address indexed account);
    event TokensPaused();
    event TokensUnpaused();
    event IdentityRegistryAdded(address indexed identityRegistry);
    event ComplianceAdded(address indexed compliance);
    event RecoverySuccess(address indexed lostWallet, address indexed newWallet, address indexed investorOnchainID);
    event AddressFrozen(address indexed addr, bool indexed isFrozen, address indexed owner);

    // Agent management
    event AgentAdded(address indexed agent);
    event AgentRemoved(address indexed agent);

    /**
     * @notice Mints tokens to an address
     * @param _to Recipient address
     * @param _amount Amount to mint
     */
    function mint(address _to, uint256 _amount) external;

    /**
     * @notice Burns tokens from an address
     * @param _from Address to burn from
     * @param _amount Amount to burn
     */
    function burn(address _from, uint256 _amount) external;

    /**
     * @notice Batch mints tokens to multiple addresses
     * @param _toList Array of recipient addresses
     * @param _amounts Array of amounts to mint
     */
    function batchMint(address[] calldata _toList, uint256[] calldata _amounts) external;

    /**
     * @notice Batch burns tokens from multiple addresses
     * @param _fromList Array of addresses to burn from
     * @param _amounts Array of amounts to burn
     */
    function batchBurn(address[] calldata _fromList, uint256[] calldata _amounts) external;

    /**
     * @notice Batch transfers tokens to multiple addresses
     * @param _toList Array of recipient addresses
     * @param _amounts Array of amounts to transfer
     */
    function batchTransfer(address[] calldata _toList, uint256[] calldata _amounts) external;

    /**
     * @notice Forces a transfer between addresses (agent only)
     * @param _from Source address
     * @param _to Destination address
     * @param _amount Amount to transfer
     * @return success Whether the transfer succeeded
     */
    function forcedTransfer(address _from, address _to, uint256 _amount) external returns (bool success);

    /**
     * @notice Pauses all token transfers
     */
    function pause() external;

    /**
     * @notice Unpauses token transfers
     */
    function unpause() external;

    /**
     * @notice Freezes an address
     * @param _account The address to freeze
     */
    function freezeAddress(address _account) external;

    /**
     * @notice Unfreezes an address
     * @param _account The address to unfreeze
     */
    function unfreezeAddress(address _account) external;

    /**
     * @notice Batch freezes addresses
     * @param _accounts Array of addresses to freeze
     */
    function batchFreezeAddress(address[] calldata _accounts) external;

    /**
     * @notice Batch unfreezes addresses
     * @param _accounts Array of addresses to unfreeze
     */
    function batchUnfreezeAddress(address[] calldata _accounts) external;

    /**
     * @notice Recovers tokens from a lost wallet
     * @param _lostWallet The lost wallet address
     * @param _newWallet The new wallet address
     * @param _investorOnchainID The investor's OnchainID address
     * @return success Whether the recovery succeeded
     */
    function recoveryAddress(
        address _lostWallet,
        address _newWallet,
        address _investorOnchainID
    ) external returns (bool success);

    /**
     * @notice Sets the identity registry
     * @param _identityRegistry The identity registry address
     */
    function setIdentityRegistry(address _identityRegistry) external;

    /**
     * @notice Sets the compliance contract
     * @param _compliance The compliance contract address
     */
    function setCompliance(address _compliance) external;

    /**
     * @notice Adds an agent
     * @param _agent The agent address to add
     */
    function addAgent(address _agent) external;

    /**
     * @notice Removes an agent
     * @param _agent The agent address to remove
     */
    function removeAgent(address _agent) external;

    /**
     * @notice Returns whether the token is paused
     * @return paused Whether the token is paused
     */
    function paused() external view returns (bool paused);

    /**
     * @notice Returns whether an address is frozen
     * @param _account The address to check
     * @return frozen Whether the address is frozen
     */
    function isFrozen(address _account) external view returns (bool frozen);

    /**
     * @notice Returns whether an address is an agent
     * @param _account The address to check
     * @return agent Whether the address is an agent
     */
    function isAgent(address _account) external view returns (bool agent);

    /**
     * @notice Returns the identity registry
     * @return registry The identity registry
     */
    function identityRegistry() external view returns (IIdentityRegistry registry);

    /**
     * @notice Returns the compliance contract
     * @return compliance The compliance contract
     */
    function compliance() external view returns (IModularCompliance compliance);

    /**
     * @notice Returns the OnchainID of the token
     * @return onchainID The token's OnchainID
     */
    function onchainID() external view returns (address onchainID);

    /**
     * @notice Returns the token version
     * @return version The token version string
     */
    function version() external pure returns (string memory version);
}
