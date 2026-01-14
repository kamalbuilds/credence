// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "./IClaimIssuer.sol";

/**
 * @title ITrustedIssuersRegistry
 * @notice Interface for the ERC-3643 Trusted Issuers Registry
 * @dev Manages which claim issuers are trusted for specific claim topics
 */
interface ITrustedIssuersRegistry {
    event TrustedIssuerAdded(IClaimIssuer indexed trustedIssuer, uint256[] claimTopics);
    event TrustedIssuerRemoved(IClaimIssuer indexed trustedIssuer);
    event ClaimTopicsUpdated(IClaimIssuer indexed trustedIssuer, uint256[] claimTopics);

    /**
     * @notice Adds a trusted issuer
     * @param _trustedIssuer The claim issuer to add
     * @param _claimTopics The topics this issuer is trusted for
     */
    function addTrustedIssuer(IClaimIssuer _trustedIssuer, uint256[] calldata _claimTopics) external;

    /**
     * @notice Removes a trusted issuer
     * @param _trustedIssuer The claim issuer to remove
     */
    function removeTrustedIssuer(IClaimIssuer _trustedIssuer) external;

    /**
     * @notice Updates the claim topics for a trusted issuer
     * @param _trustedIssuer The claim issuer
     * @param _claimTopics The new claim topics
     */
    function updateIssuerClaimTopics(IClaimIssuer _trustedIssuer, uint256[] calldata _claimTopics) external;

    /**
     * @notice Gets all trusted issuers
     * @return issuers Array of trusted claim issuers
     */
    function getTrustedIssuers() external view returns (IClaimIssuer[] memory issuers);

    /**
     * @notice Gets trusted issuers for a specific claim topic
     * @param _claimTopic The claim topic
     * @return issuers Array of trusted issuers for that topic
     */
    function getTrustedIssuersForClaimTopic(uint256 _claimTopic) external view returns (IClaimIssuer[] memory issuers);

    /**
     * @notice Checks if an issuer is trusted
     * @param _issuer The claim issuer address
     * @return trusted Whether the issuer is trusted
     */
    function isTrustedIssuer(address _issuer) external view returns (bool trusted);

    /**
     * @notice Gets the claim topics for a trusted issuer
     * @param _trustedIssuer The claim issuer
     * @return claimTopics Array of claim topics
     */
    function getTrustedIssuerClaimTopics(IClaimIssuer _trustedIssuer) external view returns (uint256[] memory claimTopics);

    /**
     * @notice Checks if a claim topic is trusted for an issuer
     * @param _issuer The claim issuer
     * @param _claimTopic The claim topic
     * @return trusted Whether the topic is trusted for that issuer
     */
    function hasClaimTopic(address _issuer, uint256 _claimTopic) external view returns (bool trusted);
}
