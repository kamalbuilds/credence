// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IIdentityRegistry.sol";
import "../interfaces/IIdentity.sol";
import "../interfaces/IClaimIssuer.sol";
import "../interfaces/IClaimTopicsRegistry.sol";
import "../interfaces/ITrustedIssuersRegistry.sol";
import "../interfaces/IIdentityRegistryStorage.sol";

/**
 * @title IdentityRegistry
 * @notice Manages the relationship between wallet addresses and OnchainID identities
 * @dev Core component of ERC-3643 T-REX protocol for investor verification
 */
contract IdentityRegistry is Ownable, IIdentityRegistry {
    // =============================================================
    //                           STORAGE
    // =============================================================

    /// @notice Identity storage contract
    IIdentityRegistryStorage private _identityStorage;

    /// @notice Claim topics registry
    IClaimTopicsRegistry private _topicsRegistry;

    /// @notice Trusted issuers registry
    ITrustedIssuersRegistry private _issuersRegistry;

    /// @notice Mapping of registration agents
    mapping(address => bool) private _agents;

    // =============================================================
    //                          MODIFIERS
    // =============================================================

    /**
     * @notice Ensures caller is an agent or owner
     */
    modifier onlyAgentOrOwner() {
        require(_agents[msg.sender] || msg.sender == owner(), "IdentityRegistry: caller is not agent");
        _;
    }

    // =============================================================
    //                        CONSTRUCTOR
    // =============================================================

    /**
     * @notice Constructs the IdentityRegistry
     * @param _trustedIssuersRegistryAddress Trusted issuers registry address
     * @param _claimTopicsRegistryAddress Claim topics registry address
     * @param _identityStorageAddress Identity storage address
     */
    constructor(
        address _trustedIssuersRegistryAddress,
        address _claimTopicsRegistryAddress,
        address _identityStorageAddress
    ) Ownable(msg.sender) {
        require(_trustedIssuersRegistryAddress != address(0), "IdentityRegistry: invalid issuers registry");
        require(_claimTopicsRegistryAddress != address(0), "IdentityRegistry: invalid topics registry");
        require(_identityStorageAddress != address(0), "IdentityRegistry: invalid storage");

        _issuersRegistry = ITrustedIssuersRegistry(_trustedIssuersRegistryAddress);
        _topicsRegistry = IClaimTopicsRegistry(_claimTopicsRegistryAddress);
        _identityStorage = IIdentityRegistryStorage(_identityStorageAddress);

        // Add deployer as initial agent
        _agents[msg.sender] = true;
    }

    // =============================================================
    //                     AGENT MANAGEMENT
    // =============================================================

    /**
     * @notice Adds an agent
     * @param _agent The agent address to add
     */
    function addAgent(address _agent) external onlyOwner {
        require(_agent != address(0), "IdentityRegistry: invalid agent");
        _agents[_agent] = true;
    }

    /**
     * @notice Removes an agent
     * @param _agent The agent address to remove
     */
    function removeAgent(address _agent) external onlyOwner {
        _agents[_agent] = false;
    }

    /**
     * @notice Checks if an address is an agent
     * @param _agent The address to check
     * @return Whether the address is an agent
     */
    function isAgent(address _agent) external view returns (bool) {
        return _agents[_agent];
    }

    // =============================================================
    //                  IDENTITY REGISTRATION
    // =============================================================

    /**
     * @inheritdoc IIdentityRegistry
     */
    function registerIdentity(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) external override onlyAgentOrOwner {
        require(_userAddress != address(0), "IdentityRegistry: invalid user address");
        require(address(_identity) != address(0), "IdentityRegistry: invalid identity");

        _identityStorage.addIdentityToStorage(_userAddress, _identity, _country);

        emit IdentityRegistered(_userAddress, _identity);
    }

    /**
     * @inheritdoc IIdentityRegistry
     */
    function batchRegisterIdentity(
        address[] calldata _userAddresses,
        IIdentity[] calldata _identities,
        uint16[] calldata _countries
    ) external override onlyAgentOrOwner {
        require(
            _userAddresses.length == _identities.length && _identities.length == _countries.length,
            "IdentityRegistry: array length mismatch"
        );

        for (uint256 i = 0; i < _userAddresses.length; i++) {
            _identityStorage.addIdentityToStorage(_userAddresses[i], _identities[i], _countries[i]);
            emit IdentityRegistered(_userAddresses[i], _identities[i]);
        }
    }

    /**
     * @inheritdoc IIdentityRegistry
     */
    function deleteIdentity(address _userAddress) external override onlyAgentOrOwner {
        IIdentity storedId = _identityStorage.storedIdentity(_userAddress);
        require(address(storedId) != address(0), "IdentityRegistry: identity not found");

        _identityStorage.removeIdentityFromStorage(_userAddress);

        emit IdentityRemoved(_userAddress, storedId);
    }

    /**
     * @inheritdoc IIdentityRegistry
     */
    function updateIdentity(
        address _userAddress,
        IIdentity _identity
    ) external override onlyAgentOrOwner {
        IIdentity oldIdentity = _identityStorage.storedIdentity(_userAddress);
        require(address(oldIdentity) != address(0), "IdentityRegistry: identity not found");

        _identityStorage.modifyStoredIdentity(_userAddress, _identity);

        emit IdentityUpdated(oldIdentity, _identity);
    }

    /**
     * @inheritdoc IIdentityRegistry
     */
    function updateCountry(
        address _userAddress,
        uint16 _country
    ) external override onlyAgentOrOwner {
        require(address(_identityStorage.storedIdentity(_userAddress)) != address(0), "IdentityRegistry: identity not found");

        _identityStorage.modifyStoredInvestorCountry(_userAddress, _country);

        emit CountryUpdated(_userAddress, _country);
    }

    // =============================================================
    //                   REGISTRY CONFIGURATION
    // =============================================================

    /**
     * @inheritdoc IIdentityRegistry
     */
    function setClaimTopicsRegistry(address _claimTopicsRegistry) external override onlyOwner {
        require(_claimTopicsRegistry != address(0), "IdentityRegistry: invalid topics registry");
        _topicsRegistry = IClaimTopicsRegistry(_claimTopicsRegistry);
        emit ClaimTopicsRegistrySet(_claimTopicsRegistry);
    }

    /**
     * @inheritdoc IIdentityRegistry
     */
    function setTrustedIssuersRegistry(address _trustedIssuersRegistry) external override onlyOwner {
        require(_trustedIssuersRegistry != address(0), "IdentityRegistry: invalid issuers registry");
        _issuersRegistry = ITrustedIssuersRegistry(_trustedIssuersRegistry);
        emit TrustedIssuersRegistrySet(_trustedIssuersRegistry);
    }

    /**
     * @inheritdoc IIdentityRegistry
     */
    function setIdentityStorage(address _identityStorageAddress) external override onlyOwner {
        require(_identityStorageAddress != address(0), "IdentityRegistry: invalid storage");
        _identityStorage = IIdentityRegistryStorage(_identityStorageAddress);
        emit IdentityStorageSet(_identityStorageAddress);
    }

    // =============================================================
    //                      VERIFICATION
    // =============================================================

    /**
     * @inheritdoc IIdentityRegistry
     * @dev Checks if an investor has valid claims from trusted issuers for all required topics
     */
    function isVerified(address _userAddress) external view override returns (bool) {
        // Get identity
        IIdentity userIdentity = _identityStorage.storedIdentity(_userAddress);
        if (address(userIdentity) == address(0)) {
            return false;
        }

        // Get required claim topics
        uint256[] memory requiredTopics = _topicsRegistry.getClaimTopics();
        if (requiredTopics.length == 0) {
            // If no topics required, identity existence is sufficient
            return true;
        }

        // Check each required topic
        for (uint256 i = 0; i < requiredTopics.length; i++) {
            if (!_hasValidClaimForTopic(userIdentity, requiredTopics[i])) {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice Checks if an identity has a valid claim for a specific topic
     * @param _identity The identity to check
     * @param _topic The claim topic
     * @return Whether the identity has a valid claim
     */
    function _hasValidClaimForTopic(IIdentity _identity, uint256 _topic) internal view returns (bool) {
        // Get trusted issuers for this topic
        IClaimIssuer[] memory trustedIssuers = _issuersRegistry.getTrustedIssuersForClaimTopic(_topic);
        if (trustedIssuers.length == 0) {
            return false;
        }

        // Get claim IDs for this topic from the identity
        bytes32[] memory claimIds = _identity.getClaimIdsByTopic(_topic);
        if (claimIds.length == 0) {
            return false;
        }

        // Check each claim
        for (uint256 i = 0; i < claimIds.length; i++) {
            (uint256 topic, , address issuer, bytes memory sig, bytes memory data, ) = _identity.getClaim(claimIds[i]);

            if (topic != _topic) {
                continue;
            }

            // Check if issuer is trusted for this topic
            if (!_issuersRegistry.hasClaimTopic(issuer, _topic)) {
                continue;
            }

            // Verify claim validity with the issuer
            try IClaimIssuer(issuer).isClaimValid(_identity, _topic, sig, data) returns (bool valid) {
                if (valid) {
                    return true;
                }
            } catch {
                continue;
            }
        }

        return false;
    }

    // =============================================================
    //                       VIEW FUNCTIONS
    // =============================================================

    /**
     * @inheritdoc IIdentityRegistry
     */
    function identity(address _userAddress) external view override returns (IIdentity) {
        return _identityStorage.storedIdentity(_userAddress);
    }

    /**
     * @inheritdoc IIdentityRegistry
     */
    function investorCountry(address _userAddress) external view override returns (uint16) {
        return _identityStorage.storedInvestorCountry(_userAddress);
    }

    /**
     * @inheritdoc IIdentityRegistry
     */
    function issuersRegistry() external view override returns (ITrustedIssuersRegistry) {
        return _issuersRegistry;
    }

    /**
     * @inheritdoc IIdentityRegistry
     */
    function topicsRegistry() external view override returns (IClaimTopicsRegistry) {
        return _topicsRegistry;
    }

    /**
     * @inheritdoc IIdentityRegistry
     */
    function identityStorage() external view override returns (IIdentityRegistryStorage) {
        return _identityStorage;
    }

    /**
     * @inheritdoc IIdentityRegistry
     */
    function contains(address _userAddress) external view override returns (bool) {
        return address(_identityStorage.storedIdentity(_userAddress)) != address(0);
    }
}
