// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ITrustedIssuersRegistry.sol";
import "../interfaces/IClaimIssuer.sol";

/**
 * @title TrustedIssuersRegistry
 * @notice Manages trusted claim issuers and their authorized claim topics
 * @dev Part of the ERC-3643 T-REX protocol
 */
contract TrustedIssuersRegistry is Ownable, ITrustedIssuersRegistry {
    // =============================================================
    //                           STORAGE
    // =============================================================

    /// @notice Array of trusted issuers
    IClaimIssuer[] private _trustedIssuers;

    /// @notice Mapping from issuer address to trusted status
    mapping(address => bool) private _isTrusted;

    /// @notice Mapping from issuer to their claim topics
    mapping(address => uint256[]) private _issuerClaimTopics;

    /// @notice Mapping from issuer to topic to existence
    mapping(address => mapping(uint256 => bool)) private _hasClaimTopic;

    /// @notice Mapping from claim topic to trusted issuers for that topic
    mapping(uint256 => IClaimIssuer[]) private _topicToIssuers;

    /// @notice Maximum number of trusted issuers
    uint256 public constant MAX_TRUSTED_ISSUERS = 50;

    /// @notice Maximum topics per issuer
    uint256 public constant MAX_TOPICS_PER_ISSUER = 15;

    // =============================================================
    //                        CONSTRUCTOR
    // =============================================================

    constructor() Ownable(msg.sender) {}

    // =============================================================
    //                     ISSUER MANAGEMENT
    // =============================================================

    /**
     * @inheritdoc ITrustedIssuersRegistry
     */
    function addTrustedIssuer(
        IClaimIssuer _trustedIssuer,
        uint256[] calldata _claimTopics
    ) external override onlyOwner {
        require(address(_trustedIssuer) != address(0), "TrustedIssuersRegistry: invalid issuer");
        require(!_isTrusted[address(_trustedIssuer)], "TrustedIssuersRegistry: issuer already exists");
        require(_trustedIssuers.length < MAX_TRUSTED_ISSUERS, "TrustedIssuersRegistry: max issuers reached");
        require(_claimTopics.length > 0, "TrustedIssuersRegistry: no claim topics");
        require(_claimTopics.length <= MAX_TOPICS_PER_ISSUER, "TrustedIssuersRegistry: too many topics");

        _trustedIssuers.push(_trustedIssuer);
        _isTrusted[address(_trustedIssuer)] = true;

        for (uint256 i = 0; i < _claimTopics.length; i++) {
            _issuerClaimTopics[address(_trustedIssuer)].push(_claimTopics[i]);
            _hasClaimTopic[address(_trustedIssuer)][_claimTopics[i]] = true;
            _topicToIssuers[_claimTopics[i]].push(_trustedIssuer);
        }

        emit TrustedIssuerAdded(_trustedIssuer, _claimTopics);
    }

    /**
     * @inheritdoc ITrustedIssuersRegistry
     */
    function removeTrustedIssuer(IClaimIssuer _trustedIssuer) external override onlyOwner {
        require(_isTrusted[address(_trustedIssuer)], "TrustedIssuersRegistry: issuer not found");

        // Remove from topic mappings
        uint256[] memory topics = _issuerClaimTopics[address(_trustedIssuer)];
        for (uint256 i = 0; i < topics.length; i++) {
            _hasClaimTopic[address(_trustedIssuer)][topics[i]] = false;
            _removeIssuerFromTopic(_trustedIssuer, topics[i]);
        }

        // Remove from main list
        for (uint256 i = 0; i < _trustedIssuers.length; i++) {
            if (_trustedIssuers[i] == _trustedIssuer) {
                _trustedIssuers[i] = _trustedIssuers[_trustedIssuers.length - 1];
                _trustedIssuers.pop();
                break;
            }
        }

        delete _issuerClaimTopics[address(_trustedIssuer)];
        _isTrusted[address(_trustedIssuer)] = false;

        emit TrustedIssuerRemoved(_trustedIssuer);
    }

    /**
     * @inheritdoc ITrustedIssuersRegistry
     */
    function updateIssuerClaimTopics(
        IClaimIssuer _trustedIssuer,
        uint256[] calldata _claimTopics
    ) external override onlyOwner {
        require(_isTrusted[address(_trustedIssuer)], "TrustedIssuersRegistry: issuer not found");
        require(_claimTopics.length > 0, "TrustedIssuersRegistry: no claim topics");
        require(_claimTopics.length <= MAX_TOPICS_PER_ISSUER, "TrustedIssuersRegistry: too many topics");

        // Remove old topics
        uint256[] memory oldTopics = _issuerClaimTopics[address(_trustedIssuer)];
        for (uint256 i = 0; i < oldTopics.length; i++) {
            _hasClaimTopic[address(_trustedIssuer)][oldTopics[i]] = false;
            _removeIssuerFromTopic(_trustedIssuer, oldTopics[i]);
        }

        // Set new topics
        delete _issuerClaimTopics[address(_trustedIssuer)];
        for (uint256 i = 0; i < _claimTopics.length; i++) {
            _issuerClaimTopics[address(_trustedIssuer)].push(_claimTopics[i]);
            _hasClaimTopic[address(_trustedIssuer)][_claimTopics[i]] = true;
            _topicToIssuers[_claimTopics[i]].push(_trustedIssuer);
        }

        emit ClaimTopicsUpdated(_trustedIssuer, _claimTopics);
    }

    // =============================================================
    //                       INTERNAL FUNCTIONS
    // =============================================================

    /**
     * @notice Removes an issuer from a topic's issuer list
     * @param _issuer The issuer to remove
     * @param _topic The topic
     */
    function _removeIssuerFromTopic(IClaimIssuer _issuer, uint256 _topic) internal {
        IClaimIssuer[] storage issuers = _topicToIssuers[_topic];
        for (uint256 i = 0; i < issuers.length; i++) {
            if (issuers[i] == _issuer) {
                issuers[i] = issuers[issuers.length - 1];
                issuers.pop();
                break;
            }
        }
    }

    // =============================================================
    //                       VIEW FUNCTIONS
    // =============================================================

    /**
     * @inheritdoc ITrustedIssuersRegistry
     */
    function getTrustedIssuers() external view override returns (IClaimIssuer[] memory) {
        return _trustedIssuers;
    }

    /**
     * @inheritdoc ITrustedIssuersRegistry
     */
    function getTrustedIssuersForClaimTopic(
        uint256 _claimTopic
    ) external view override returns (IClaimIssuer[] memory) {
        return _topicToIssuers[_claimTopic];
    }

    /**
     * @inheritdoc ITrustedIssuersRegistry
     */
    function isTrustedIssuer(address _issuer) external view override returns (bool) {
        return _isTrusted[_issuer];
    }

    /**
     * @inheritdoc ITrustedIssuersRegistry
     */
    function getTrustedIssuerClaimTopics(
        IClaimIssuer _trustedIssuer
    ) external view override returns (uint256[] memory) {
        return _issuerClaimTopics[address(_trustedIssuer)];
    }

    /**
     * @inheritdoc ITrustedIssuersRegistry
     */
    function hasClaimTopic(
        address _issuer,
        uint256 _claimTopic
    ) external view override returns (bool) {
        return _hasClaimTopic[_issuer][_claimTopic];
    }
}
