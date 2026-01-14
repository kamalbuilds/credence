// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IClaimTopicsRegistry.sol";

/**
 * @title ClaimTopicsRegistry
 * @notice Manages the list of claim topics required for token holder verification
 * @dev Part of the ERC-3643 T-REX protocol
 */
contract ClaimTopicsRegistry is Ownable, IClaimTopicsRegistry {
    // =============================================================
    //                           STORAGE
    // =============================================================

    /// @notice Array of required claim topics
    uint256[] private _claimTopics;

    /// @notice Mapping to track if a topic exists
    mapping(uint256 => bool) private _claimTopicExists;

    /// @notice Maximum number of claim topics allowed
    uint256 public constant MAX_CLAIM_TOPICS = 15;

    // =============================================================
    //                           EVENTS
    // =============================================================

    // Events are inherited from IClaimTopicsRegistry

    // =============================================================
    //                        CONSTRUCTOR
    // =============================================================

    constructor() Ownable(msg.sender) {}

    // =============================================================
    //                      TOPIC MANAGEMENT
    // =============================================================

    /**
     * @inheritdoc IClaimTopicsRegistry
     */
    function addClaimTopic(uint256 _claimTopic) external override onlyOwner {
        require(_claimTopics.length < MAX_CLAIM_TOPICS, "ClaimTopicsRegistry: max topics reached");
        require(!_claimTopicExists[_claimTopic], "ClaimTopicsRegistry: topic already exists");

        _claimTopics.push(_claimTopic);
        _claimTopicExists[_claimTopic] = true;

        emit ClaimTopicAdded(_claimTopic);
    }

    /**
     * @inheritdoc IClaimTopicsRegistry
     */
    function removeClaimTopic(uint256 _claimTopic) external override onlyOwner {
        require(_claimTopicExists[_claimTopic], "ClaimTopicsRegistry: topic does not exist");

        // Find and remove the topic
        for (uint256 i = 0; i < _claimTopics.length; i++) {
            if (_claimTopics[i] == _claimTopic) {
                _claimTopics[i] = _claimTopics[_claimTopics.length - 1];
                _claimTopics.pop();
                break;
            }
        }

        _claimTopicExists[_claimTopic] = false;

        emit ClaimTopicRemoved(_claimTopic);
    }

    /**
     * @inheritdoc IClaimTopicsRegistry
     */
    function getClaimTopics() external view override returns (uint256[] memory) {
        return _claimTopics;
    }

    /**
     * @notice Checks if a claim topic is required
     * @param _claimTopic The topic to check
     * @return exists Whether the topic is required
     */
    function isClaimTopicRequired(uint256 _claimTopic) external view returns (bool) {
        return _claimTopicExists[_claimTopic];
    }
}
