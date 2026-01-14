// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "./AbstractComplianceModule.sol";
import "../../verifier/ISP1Verifier.sol";
import "../../verifier/SP1CredentialVerifier.sol";

/**
 * @title ZKCredentialModule
 * @notice Compliance module that verifies transfers based on ZK credential proofs
 * @dev Integrates SP1 zkVM proofs with ERC-3643 compliance system
 *      This module requires users to have valid ZK-verified credentials
 *      before they can send or receive tokens
 */
contract ZKCredentialModule is AbstractComplianceModule {
    // =============================================================
    //                           STORAGE
    // =============================================================

    /// @notice The SP1 credential verifier contract
    SP1CredentialVerifier public credentialVerifier;

    /// @notice Mapping of compliance to required credential types
    mapping(address => uint256[]) private _requiredCredentialTypes;

    /// @notice Mapping to track if a credential type is required
    mapping(address => mapping(uint256 => bool)) private _isCredentialRequired;

    /// @notice Mapping of user address to their credential verification status cache
    /// @dev Used to avoid repeated expensive verification calls
    mapping(address => mapping(address => bool)) private _verificationCache;

    /// @notice Mapping to track cache validity
    mapping(address => mapping(address => uint256)) private _cacheTimestamp;

    /// @notice Cache validity duration (default 1 hour)
    uint256 public cacheValidityDuration = 1 hours;

    // =============================================================
    //                           EVENTS
    // =============================================================

    event CredentialVerifierSet(address indexed oldVerifier, address indexed newVerifier);
    event CredentialTypeRequired(address indexed compliance, uint256 indexed credentialType);
    event CredentialTypeRemoved(address indexed compliance, uint256 indexed credentialType);
    event CacheValidityUpdated(uint256 oldDuration, uint256 newDuration);
    event VerificationCacheCleared(address indexed compliance, address indexed user);

    // =============================================================
    //                           ERRORS
    // =============================================================

    error InvalidVerifier();
    error CredentialTypeAlreadyRequired();
    error CredentialTypeNotRequired();
    error NoCredentialTypesConfigured();

    // =============================================================
    //                        CONSTRUCTOR
    // =============================================================

    /**
     * @notice Constructs the ZKCredentialModule
     * @param _credentialVerifier Address of the SP1 credential verifier
     */
    constructor(address _credentialVerifier) AbstractComplianceModule() {
        if (_credentialVerifier == address(0)) revert InvalidVerifier();
        credentialVerifier = SP1CredentialVerifier(_credentialVerifier);
    }

    // =============================================================
    //                    CONFIGURATION
    // =============================================================

    /**
     * @notice Updates the credential verifier contract
     * @param _newVerifier The new verifier address
     */
    function setCredentialVerifier(address _newVerifier) external onlyOwner {
        if (_newVerifier == address(0)) revert InvalidVerifier();

        address oldVerifier = address(credentialVerifier);
        credentialVerifier = SP1CredentialVerifier(_newVerifier);

        emit CredentialVerifierSet(oldVerifier, _newVerifier);
    }

    /**
     * @notice Adds a required credential type for a compliance
     * @param _compliance The compliance contract
     * @param _credentialType The credential type to require
     */
    function addRequiredCredentialType(
        address _compliance,
        uint256 _credentialType
    ) external onlyOwner {
        if (_isCredentialRequired[_compliance][_credentialType]) {
            revert CredentialTypeAlreadyRequired();
        }

        _requiredCredentialTypes[_compliance].push(_credentialType);
        _isCredentialRequired[_compliance][_credentialType] = true;

        emit CredentialTypeRequired(_compliance, _credentialType);
    }

    /**
     * @notice Removes a required credential type
     * @param _compliance The compliance contract
     * @param _credentialType The credential type to remove
     */
    function removeRequiredCredentialType(
        address _compliance,
        uint256 _credentialType
    ) external onlyOwner {
        if (!_isCredentialRequired[_compliance][_credentialType]) {
            revert CredentialTypeNotRequired();
        }

        uint256[] storage types = _requiredCredentialTypes[_compliance];
        for (uint256 i = 0; i < types.length; i++) {
            if (types[i] == _credentialType) {
                types[i] = types[types.length - 1];
                types.pop();
                break;
            }
        }

        _isCredentialRequired[_compliance][_credentialType] = false;

        emit CredentialTypeRemoved(_compliance, _credentialType);
    }

    /**
     * @notice Batch adds required credential types
     * @param _compliance The compliance contract
     * @param _credentialTypes Array of credential types to require
     */
    function batchAddRequiredCredentialTypes(
        address _compliance,
        uint256[] calldata _credentialTypes
    ) external onlyOwner {
        for (uint256 i = 0; i < _credentialTypes.length; i++) {
            if (!_isCredentialRequired[_compliance][_credentialTypes[i]]) {
                _requiredCredentialTypes[_compliance].push(_credentialTypes[i]);
                _isCredentialRequired[_compliance][_credentialTypes[i]] = true;
                emit CredentialTypeRequired(_compliance, _credentialTypes[i]);
            }
        }
    }

    /**
     * @notice Sets the cache validity duration
     * @param _duration New duration in seconds
     */
    function setCacheValidityDuration(uint256 _duration) external onlyOwner {
        uint256 oldDuration = cacheValidityDuration;
        cacheValidityDuration = _duration;
        emit CacheValidityUpdated(oldDuration, _duration);
    }

    /**
     * @notice Clears verification cache for a user
     * @param _compliance The compliance contract
     * @param _user The user address
     */
    function clearVerificationCache(address _compliance, address _user) external onlyOwner {
        delete _verificationCache[_compliance][_user];
        delete _cacheTimestamp[_compliance][_user];
        emit VerificationCacheCleared(_compliance, _user);
    }

    // =============================================================
    //                    COMPLIANCE CHECK
    // =============================================================

    /**
     * @inheritdoc IComplianceModule
     * @dev Checks if both sender and receiver have valid ZK credentials
     */
    function moduleCheck(
        address _from,
        address _to,
        uint256 /*_amount*/,
        address _compliance
    ) external view override returns (bool) {
        uint256[] memory requiredTypes = _requiredCredentialTypes[_compliance];

        // If no credential types are configured, allow all transfers
        if (requiredTypes.length == 0) {
            return true;
        }

        // Check sender credentials (skip for mint - from is zero address)
        if (_from != address(0)) {
            if (!_hasValidCredentials(_from, _compliance, requiredTypes)) {
                return false;
            }
        }

        // Check receiver credentials (skip for burn - to is zero address)
        if (_to != address(0)) {
            if (!_hasValidCredentials(_to, _compliance, requiredTypes)) {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice Checks if a user has all required valid credentials
     * @param _user The user address
     * @param _compliance The compliance contract
     * @param _requiredTypes Array of required credential types
     * @return Whether the user has all required credentials
     */
    function _hasValidCredentials(
        address _user,
        address _compliance,
        uint256[] memory _requiredTypes
    ) internal view returns (bool) {
        // Check cache first
        if (_isCacheValid(_compliance, _user)) {
            return _verificationCache[_compliance][_user];
        }

        // Verify each required credential type
        for (uint256 i = 0; i < _requiredTypes.length; i++) {
            if (!credentialVerifier.hasValidCredentialOfType(_user, _requiredTypes[i])) {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice Checks if the verification cache is still valid
     */
    function _isCacheValid(address _compliance, address _user) internal view returns (bool) {
        uint256 cacheTime = _cacheTimestamp[_compliance][_user];
        return cacheTime > 0 && block.timestamp <= cacheTime + cacheValidityDuration;
    }

    // =============================================================
    //                    MODULE ACTIONS
    // =============================================================

    /**
     * @inheritdoc IComplianceModule
     * @dev Updates verification cache after successful transfer
     */
    function moduleTransferAction(
        address _from,
        address _to,
        uint256 /*_amount*/,
        address _compliance
    ) external override onlyBoundCompliance {
        // Update cache for both parties after successful transfer
        if (_from != address(0)) {
            _updateVerificationCache(_compliance, _from);
        }
        if (_to != address(0)) {
            _updateVerificationCache(_compliance, _to);
        }
    }

    /**
     * @notice Updates the verification cache for a user
     */
    function _updateVerificationCache(address _compliance, address _user) internal {
        uint256[] memory requiredTypes = _requiredCredentialTypes[_compliance];
        bool isVerified = true;

        for (uint256 i = 0; i < requiredTypes.length; i++) {
            if (!credentialVerifier.hasValidCredentialOfType(_user, requiredTypes[i])) {
                isVerified = false;
                break;
            }
        }

        _verificationCache[_compliance][_user] = isVerified;
        _cacheTimestamp[_compliance][_user] = block.timestamp;
    }

    // =============================================================
    //                    VIEW FUNCTIONS
    // =============================================================

    /**
     * @notice Gets the required credential types for a compliance
     * @param _compliance The compliance contract
     * @return Array of required credential type IDs
     */
    function getRequiredCredentialTypes(address _compliance) external view returns (uint256[] memory) {
        return _requiredCredentialTypes[_compliance];
    }

    /**
     * @notice Checks if a credential type is required
     * @param _compliance The compliance contract
     * @param _credentialType The credential type to check
     * @return Whether the credential type is required
     */
    function isCredentialTypeRequired(
        address _compliance,
        uint256 _credentialType
    ) external view returns (bool) {
        return _isCredentialRequired[_compliance][_credentialType];
    }

    /**
     * @notice Checks if a user has valid credentials for a compliance
     * @param _compliance The compliance contract
     * @param _user The user address
     * @return Whether the user has valid credentials
     */
    function hasValidCredentials(address _compliance, address _user) external view returns (bool) {
        uint256[] memory requiredTypes = _requiredCredentialTypes[_compliance];
        if (requiredTypes.length == 0) {
            return true;
        }
        return _hasValidCredentials(_user, _compliance, requiredTypes);
    }

    /**
     * @inheritdoc IComplianceModule
     */
    function name() external pure override returns (string memory) {
        return "ZKCredentialModule";
    }

    /**
     * @inheritdoc IComplianceModule
     * @dev This module is NOT plug-and-play as it requires credential type configuration
     */
    function isPlugAndPlay() public pure override returns (bool) {
        return false;
    }

    /**
     * @inheritdoc IComplianceModule
     * @dev Compliance can only bind if credential types are configured
     */
    function canComplianceBind(address _compliance) public view override returns (bool) {
        return _requiredCredentialTypes[_compliance].length > 0;
    }
}
