// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "./AbstractComplianceModule.sol";
import "../../interfaces/IVerifiToken.sol";
import "../../interfaces/IIdentityRegistry.sol";
import "../../interfaces/IIdentity.sol";

/**
 * @title AccreditedInvestorModule
 * @notice Compliance module that requires accredited investor status
 * @dev Checks for specific claim topics that prove accredited investor status
 */
contract AccreditedInvestorModule is AbstractComplianceModule {
    // =============================================================
    //                         CONSTANTS
    // =============================================================

    /// @notice Claim topic for accredited investor status (standard topic from ERC-3643)
    uint256 public constant ACCREDITED_INVESTOR_TOPIC = 7; // Standard topic for accredited investor

    /// @notice Claim topic for qualified investor status
    uint256 public constant QUALIFIED_INVESTOR_TOPIC = 8;

    /// @notice Claim topic for institutional investor status
    uint256 public constant INSTITUTIONAL_INVESTOR_TOPIC = 9;

    // =============================================================
    //                           STORAGE
    // =============================================================

    /// @notice Mapping of compliance to whether accreditation is required
    mapping(address => bool) private _accreditationRequired;

    /// @notice Mapping of compliance to minimum investment amount for non-accredited
    mapping(address => uint256) private _minInvestmentForNonAccredited;

    /// @notice Mapping of compliance to accepted claim topics
    mapping(address => mapping(uint256 => bool)) private _acceptedTopics;

    // =============================================================
    //                           EVENTS
    // =============================================================

    event AccreditationRequirementSet(address indexed compliance, bool required);
    event MinInvestmentSet(address indexed compliance, uint256 minAmount);
    event ClaimTopicAccepted(address indexed compliance, uint256 indexed topic);
    event ClaimTopicRejected(address indexed compliance, uint256 indexed topic);

    // =============================================================
    //                        CONSTRUCTOR
    // =============================================================

    constructor() AbstractComplianceModule() {}

    // =============================================================
    //                    CONFIGURATION
    // =============================================================

    /**
     * @notice Sets whether accreditation is required for a compliance
     * @param _compliance The compliance contract
     * @param _required Whether accreditation is required
     */
    function setAccreditationRequired(address _compliance, bool _required) external onlyOwner {
        _accreditationRequired[_compliance] = _required;
        emit AccreditationRequirementSet(_compliance, _required);
    }

    /**
     * @notice Sets the minimum investment amount for non-accredited investors
     * @param _compliance The compliance contract
     * @param _minAmount The minimum amount
     */
    function setMinInvestmentForNonAccredited(address _compliance, uint256 _minAmount) external onlyOwner {
        _minInvestmentForNonAccredited[_compliance] = _minAmount;
        emit MinInvestmentSet(_compliance, _minAmount);
    }

    /**
     * @notice Adds an accepted claim topic
     * @param _compliance The compliance contract
     * @param _topic The claim topic to accept
     */
    function addAcceptedClaimTopic(address _compliance, uint256 _topic) external onlyOwner {
        _acceptedTopics[_compliance][_topic] = true;
        emit ClaimTopicAccepted(_compliance, _topic);
    }

    /**
     * @notice Removes an accepted claim topic
     * @param _compliance The compliance contract
     * @param _topic The claim topic to reject
     */
    function removeAcceptedClaimTopic(address _compliance, uint256 _topic) external onlyOwner {
        _acceptedTopics[_compliance][_topic] = false;
        emit ClaimTopicRejected(_compliance, _topic);
    }

    /**
     * @notice Initialize default accepted topics for a compliance
     * @param _compliance The compliance contract
     */
    function initializeDefaultTopics(address _compliance) external onlyOwner {
        _acceptedTopics[_compliance][ACCREDITED_INVESTOR_TOPIC] = true;
        _acceptedTopics[_compliance][QUALIFIED_INVESTOR_TOPIC] = true;
        _acceptedTopics[_compliance][INSTITUTIONAL_INVESTOR_TOPIC] = true;

        emit ClaimTopicAccepted(_compliance, ACCREDITED_INVESTOR_TOPIC);
        emit ClaimTopicAccepted(_compliance, QUALIFIED_INVESTOR_TOPIC);
        emit ClaimTopicAccepted(_compliance, INSTITUTIONAL_INVESTOR_TOPIC);
    }

    // =============================================================
    //                    COMPLIANCE CHECK
    // =============================================================

    /**
     * @inheritdoc IComplianceModule
     */
    function moduleCheck(
        address /*_from*/,
        address _to,
        uint256 _amount,
        address _compliance
    ) external view override returns (bool) {
        // If accreditation is not required, allow the transfer
        if (!_accreditationRequired[_compliance]) {
            return true;
        }

        address token = _getToken(_compliance);
        IIdentityRegistry identityRegistry = IVerifiToken(token).identityRegistry();
        IIdentity recipientIdentity = identityRegistry.identity(_to);

        // Check if recipient has accreditation
        if (address(recipientIdentity) == address(0)) {
            return false;
        }

        // Check for any accepted accreditation topic
        if (_hasAccreditedStatus(recipientIdentity, _compliance)) {
            return true;
        }

        // If not accredited, check if there's a minimum investment exception
        uint256 minInvestment = _minInvestmentForNonAccredited[_compliance];
        if (minInvestment > 0 && _amount >= minInvestment) {
            return true;
        }

        return false;
    }

    /**
     * @notice Checks if an identity has an accepted accreditation claim
     * @param _identity The identity to check
     * @param _compliance The compliance contract
     * @return Whether the identity is accredited
     */
    function _hasAccreditedStatus(IIdentity _identity, address _compliance) internal view returns (bool) {
        // Check for accredited investor topic
        if (_acceptedTopics[_compliance][ACCREDITED_INVESTOR_TOPIC]) {
            bytes32[] memory claimIds = _identity.getClaimIdsByTopic(ACCREDITED_INVESTOR_TOPIC);
            if (claimIds.length > 0) {
                return true;
            }
        }

        // Check for qualified investor topic
        if (_acceptedTopics[_compliance][QUALIFIED_INVESTOR_TOPIC]) {
            bytes32[] memory claimIds = _identity.getClaimIdsByTopic(QUALIFIED_INVESTOR_TOPIC);
            if (claimIds.length > 0) {
                return true;
            }
        }

        // Check for institutional investor topic
        if (_acceptedTopics[_compliance][INSTITUTIONAL_INVESTOR_TOPIC]) {
            bytes32[] memory claimIds = _identity.getClaimIdsByTopic(INSTITUTIONAL_INVESTOR_TOPIC);
            if (claimIds.length > 0) {
                return true;
            }
        }

        return false;
    }

    // =============================================================
    //                    VIEW FUNCTIONS
    // =============================================================

    /**
     * @notice Checks if accreditation is required
     * @param _compliance The compliance contract
     * @return Whether accreditation is required
     */
    function isAccreditationRequired(address _compliance) external view returns (bool) {
        return _accreditationRequired[_compliance];
    }

    /**
     * @notice Gets the minimum investment for non-accredited investors
     * @param _compliance The compliance contract
     * @return The minimum investment amount
     */
    function getMinInvestmentForNonAccredited(address _compliance) external view returns (uint256) {
        return _minInvestmentForNonAccredited[_compliance];
    }

    /**
     * @notice Checks if a claim topic is accepted
     * @param _compliance The compliance contract
     * @param _topic The claim topic
     * @return Whether the topic is accepted
     */
    function isClaimTopicAccepted(address _compliance, uint256 _topic) external view returns (bool) {
        return _acceptedTopics[_compliance][_topic];
    }

    /**
     * @inheritdoc IComplianceModule
     */
    function name() external pure override returns (string memory) {
        return "AccreditedInvestorModule";
    }
}
