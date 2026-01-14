// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "./IIdentity.sol";

/**
 * @title IClaimIssuer
 * @notice Interface for Claim Issuer contracts
 * @dev Extends IIdentity with claim verification and revocation capabilities
 */
interface IClaimIssuer is IIdentity {
    event ClaimRevoked(bytes indexed signature);

    /**
     * @notice Checks if a claim is valid
     * @param _identity The identity holding the claim
     * @param claimTopic The topic of the claim
     * @param sig The signature to verify
     * @param data The claim data
     * @return claimValid Whether the claim is valid
     */
    function isClaimValid(
        IIdentity _identity,
        uint256 claimTopic,
        bytes calldata sig,
        bytes calldata data
    ) external view returns (bool claimValid);

    /**
     * @notice Checks if a claim signature has been revoked
     * @param _sig The signature to check
     * @return revoked Whether the signature is revoked
     */
    function isClaimRevoked(bytes calldata _sig) external view returns (bool revoked);

    /**
     * @notice Revokes a claim by its signature
     * @param _sig The signature to revoke
     * @return success Whether the operation succeeded
     */
    function revokeClaimBySignature(bytes calldata _sig) external returns (bool success);

    /**
     * @notice Revokes a claim by its ID on an identity
     * @param _claimId The claim ID to revoke
     * @param _identity The identity holding the claim
     * @return success Whether the operation succeeded
     */
    function revokeClaim(bytes32 _claimId, address _identity) external returns (bool success);
}
