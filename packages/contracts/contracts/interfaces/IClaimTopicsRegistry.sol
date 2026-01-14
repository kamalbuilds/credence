// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

/**
 * @title IClaimTopicsRegistry
 * @notice Interface for the ERC-3643 Claim Topics Registry
 * @dev Manages the list of claim topics required for token transfers
 */
interface IClaimTopicsRegistry {
    /**
     * @notice Emitted when a claim topic is added
     * @param claimTopic The added claim topic
     */
    event ClaimTopicAdded(uint256 indexed claimTopic);

    /**
     * @notice Emitted when a claim topic is removed
     * @param claimTopic The removed claim topic
     */
    event ClaimTopicRemoved(uint256 indexed claimTopic);

    /**
     * @notice Adds a claim topic to the registry
     * @param _claimTopic The claim topic to add
     */
    function addClaimTopic(uint256 _claimTopic) external;

    /**
     * @notice Removes a claim topic from the registry
     * @param _claimTopic The claim topic to remove
     */
    function removeClaimTopic(uint256 _claimTopic) external;

    /**
     * @notice Gets all claim topics
     * @return topics Array of claim topics
     */
    function getClaimTopics() external view returns (uint256[] memory topics);
}
