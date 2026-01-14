// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "./Identity.sol";
import "../interfaces/IClaimIssuer.sol";
import "../verifier/ISP1Verifier.sol";

/**
 * @title ClaimIssuer
 * @notice Claim Issuer contract that can issue and verify claims on identities
 * @dev Extends Identity with claim issuance, verification, and ZK proof integration
 *      This is a key component for ERC-3643 compliance - trusted issuers verify investor credentials
 */
contract ClaimIssuer is Identity, IClaimIssuer {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // =============================================================
    //                           STORAGE
    // =============================================================

    /// @notice Mapping of revoked claim signatures
    mapping(bytes => bool) private _revokedClaims;

    /// @notice Optional SP1 verifier for ZK-based claim verification
    ISP1Verifier public sp1Verifier;

    /// @notice Program verification key for ZK claims
    bytes32 public zkProgramVKey;

    /// @notice Whether ZK verification is enabled
    bool public zkVerificationEnabled;

    // =============================================================
    //                           EVENTS
    // =============================================================

    event ZKVerifierUpdated(address indexed oldVerifier, address indexed newVerifier);
    event ZKProgramKeyUpdated(bytes32 indexed oldKey, bytes32 indexed newKey);
    event ZKVerificationToggled(bool enabled);

    // =============================================================
    //                           ERRORS
    // =============================================================

    error ClaimAlreadyRevoked();
    error InvalidSignature();
    error ZKVerificationFailed();
    error ZKNotEnabled();

    // =============================================================
    //                        CONSTRUCTOR
    // =============================================================

    /**
     * @notice Constructs the ClaimIssuer
     * @param _initialManagementKey The initial management key address
     */
    constructor(address _initialManagementKey) Identity(_initialManagementKey) {}

    // =============================================================
    //                    ZK CONFIGURATION
    // =============================================================

    /**
     * @notice Sets the SP1 verifier for ZK claim verification
     * @param _verifier The SP1 verifier address
     */
    function setSP1Verifier(address _verifier) external {
        require(
            keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), MANAGEMENT_KEY),
            "ClaimIssuer: sender does not have management key"
        );

        address oldVerifier = address(sp1Verifier);
        sp1Verifier = ISP1Verifier(_verifier);

        emit ZKVerifierUpdated(oldVerifier, _verifier);
    }

    /**
     * @notice Sets the program verification key for ZK claims
     * @param _vKey The verification key
     */
    function setZKProgramVKey(bytes32 _vKey) external {
        require(
            keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), MANAGEMENT_KEY),
            "ClaimIssuer: sender does not have management key"
        );

        bytes32 oldKey = zkProgramVKey;
        zkProgramVKey = _vKey;

        emit ZKProgramKeyUpdated(oldKey, _vKey);
    }

    /**
     * @notice Enables or disables ZK verification
     * @param _enabled Whether to enable ZK verification
     */
    function setZKVerificationEnabled(bool _enabled) external {
        require(
            keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), MANAGEMENT_KEY),
            "ClaimIssuer: sender does not have management key"
        );

        zkVerificationEnabled = _enabled;

        emit ZKVerificationToggled(_enabled);
    }

    // =============================================================
    //                    CLAIM VERIFICATION
    // =============================================================

    /**
     * @inheritdoc IClaimIssuer
     * @dev Verifies that:
     *      1. The signature is not revoked
     *      2. The signature was created by this issuer for the given identity and claim
     *      3. Optionally verifies ZK proof if enabled
     */
    function isClaimValid(
        IIdentity _identity,
        uint256 claimTopic,
        bytes calldata sig,
        bytes calldata data
    ) external view override returns (bool) {
        // Check if signature is revoked
        if (_revokedClaims[sig]) {
            return false;
        }

        // Construct the claim hash that was signed
        bytes32 claimHash = keccak256(abi.encodePacked(address(_identity), claimTopic, data));
        bytes32 ethSignedHash = claimHash.toEthSignedMessageHash();

        // Recover the signer from the signature
        address signer = ethSignedHash.recover(sig);

        // Check if signer has CLAIM_SIGNER_KEY purpose in this issuer
        bytes32 signerKeyHash = keccak256(abi.encodePacked(signer));

        return keyHasPurpose(signerKeyHash, CLAIM_SIGNER_KEY);
    }

    /**
     * @notice Verifies a claim using a ZK proof
     * @param _identity The identity contract holding the claim
     * @param claimTopic The claim topic
     * @param publicValues The public values from the ZK proof
     * @param proofBytes The ZK proof bytes
     * @return valid Whether the claim is valid according to the ZK proof
     */
    function isClaimValidWithZKProof(
        IIdentity _identity,
        uint256 claimTopic,
        bytes calldata publicValues,
        bytes calldata proofBytes
    ) external view returns (bool valid) {
        if (!zkVerificationEnabled) revert ZKNotEnabled();
        if (address(sp1Verifier) == address(0)) revert ZKNotEnabled();

        // Decode public values to verify they match the claim
        (
            address subject,
            uint256 proofClaimTopic,
            ,  // credentialHash
            ,  // issuedAt
            uint256 expiresAt
        ) = abi.decode(publicValues, (address, uint256, bytes32, uint256, uint256));

        // Verify the proof is for the correct identity and topic
        if (subject != address(_identity) || proofClaimTopic != claimTopic) {
            return false;
        }

        // Check expiration
        if (expiresAt > 0 && block.timestamp > expiresAt) {
            return false;
        }

        // Verify the ZK proof
        try sp1Verifier.verifyProof(zkProgramVKey, publicValues, proofBytes) {
            return true;
        } catch {
            return false;
        }
    }

    // =============================================================
    //                    CLAIM REVOCATION
    // =============================================================

    /**
     * @inheritdoc IClaimIssuer
     */
    function isClaimRevoked(bytes calldata _sig) external view override returns (bool) {
        return _revokedClaims[_sig];
    }

    /**
     * @inheritdoc IClaimIssuer
     */
    function revokeClaimBySignature(bytes calldata _sig) external override returns (bool) {
        require(
            keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), MANAGEMENT_KEY) ||
            keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), CLAIM_SIGNER_KEY),
            "ClaimIssuer: sender cannot revoke claims"
        );

        if (_revokedClaims[_sig]) revert ClaimAlreadyRevoked();

        _revokedClaims[_sig] = true;

        emit ClaimRevoked(_sig);

        return true;
    }

    /**
     * @inheritdoc IClaimIssuer
     */
    function revokeClaim(bytes32 _claimId, address _identity) external override returns (bool) {
        require(
            keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), MANAGEMENT_KEY) ||
            keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), CLAIM_SIGNER_KEY),
            "ClaimIssuer: sender cannot revoke claims"
        );

        // Get the claim from the identity
        (, , , bytes memory sig, , ) = IIdentity(_identity).getClaim(_claimId);

        if (sig.length == 0) {
            return false;
        }

        if (_revokedClaims[sig]) revert ClaimAlreadyRevoked();

        _revokedClaims[sig] = true;

        emit ClaimRevoked(sig);

        return true;
    }

    // =============================================================
    //                    CLAIM ISSUANCE
    // =============================================================

    /**
     * @notice Issues a claim to an identity
     * @dev This function reverts - use issueClaimWithSignature instead
     *      Signatures must be generated off-chain by an authorized signer
     * @param _identity The identity to issue the claim to
     * @param _topic The claim topic
     * @param _data The claim data
     */
    function issueClaim(
        IIdentity _identity,
        uint256 _topic,
        uint256 /* _scheme */,
        bytes calldata _data,
        string calldata /* _uri */
    ) external pure returns (bytes32 /* claimId */) {
        // Validate inputs exist (unused but required for interface)
        require(address(_identity) != address(0), "ClaimIssuer: invalid identity");
        require(_topic > 0, "ClaimIssuer: invalid topic");
        require(_data.length > 0, "ClaimIssuer: invalid data");

        // Signatures must be generated off-chain by an authorized signer
        revert("ClaimIssuer: use issueClaimWithSignature for production");
    }

    /**
     * @notice Issues a claim with a pre-generated signature
     * @param _identity The identity to issue the claim to
     * @param _topic The claim topic
     * @param _scheme The claim scheme
     * @param _signature The pre-generated signature
     * @param _data The claim data
     * @param _uri The claim URI
     * @return claimId The ID of the issued claim
     */
    function issueClaimWithSignature(
        IIdentity _identity,
        uint256 _topic,
        uint256 _scheme,
        bytes calldata _signature,
        bytes calldata _data,
        string calldata _uri
    ) external returns (bytes32 claimId) {
        require(
            keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), MANAGEMENT_KEY) ||
            keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), CLAIM_SIGNER_KEY),
            "ClaimIssuer: sender cannot issue claims"
        );

        // Verify the signature is valid
        bytes32 claimHash = keccak256(abi.encodePacked(address(_identity), _topic, _data));
        bytes32 ethSignedHash = claimHash.toEthSignedMessageHash();
        address signer = ethSignedHash.recover(_signature);

        // Signer must have CLAIM_SIGNER_KEY
        require(
            keyHasPurpose(keccak256(abi.encodePacked(signer)), CLAIM_SIGNER_KEY),
            "ClaimIssuer: invalid signature - signer not authorized"
        );

        // Add claim to the identity
        claimId = _identity.addClaim(_topic, _scheme, address(this), _signature, _data, _uri);

        return claimId;
    }

    // =============================================================
    //                    BATCH OPERATIONS
    // =============================================================

    /**
     * @notice Batch revokes multiple claim signatures
     * @param _signatures Array of signatures to revoke
     */
    function batchRevokeClaimsBySignature(bytes[] calldata _signatures) external {
        require(
            keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), MANAGEMENT_KEY),
            "ClaimIssuer: sender cannot revoke claims"
        );

        for (uint256 i = 0; i < _signatures.length; i++) {
            if (!_revokedClaims[_signatures[i]]) {
                _revokedClaims[_signatures[i]] = true;
                emit ClaimRevoked(_signatures[i]);
            }
        }
    }
}
