// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ISP1Verifier.sol";

/**
 * @title SP1CredentialVerifier
 * @notice Verifies zero-knowledge proofs for credential verification using SP1 zkVM
 * @dev Integrates with Succinct Labs SP1 verifier contracts
 */
contract SP1CredentialVerifier is Ownable, ReentrancyGuard {
    // =============================================================
    //                           STORAGE
    // =============================================================

    /// @notice The SP1 verifier contract
    ISP1Verifier public sp1Verifier;

    /// @notice The verification key for the credential verification program
    bytes32 public programVKey;

    /// @notice Mapping of verified credential hashes
    mapping(bytes32 => bool) public verifiedCredentials;

    /// @notice Mapping of user address to their verified credential hashes
    mapping(address => bytes32[]) public userCredentials;

    /// @notice Mapping to track if a proof has been used (prevent replay)
    mapping(bytes32 => bool) public usedProofs;

    /// @notice Credential expiration time (0 means no expiration)
    uint256 public credentialExpirationTime;

    /// @notice Mapping of credential hash to verification timestamp
    mapping(bytes32 => uint256) public credentialTimestamps;

    // =============================================================
    //                          STRUCTS
    // =============================================================

    /**
     * @notice Structure representing verified credential data
     */
    struct VerifiedCredential {
        bytes32 credentialHash;
        address subject;
        uint256 credentialType;
        uint256 issuedAt;
        uint256 expiresAt;
        bool isValid;
    }

    /// @notice Mapping of credential hash to credential data
    mapping(bytes32 => VerifiedCredential) public credentials;

    // =============================================================
    //                           EVENTS
    // =============================================================

    event CredentialVerified(
        bytes32 indexed credentialHash,
        address indexed subject,
        uint256 indexed credentialType,
        uint256 timestamp
    );

    event CredentialRevoked(bytes32 indexed credentialHash, address indexed revoker);
    event SP1VerifierUpdated(address indexed oldVerifier, address indexed newVerifier);
    event ProgramVKeyUpdated(bytes32 indexed oldKey, bytes32 indexed newKey);
    event ExpirationTimeUpdated(uint256 oldTime, uint256 newTime);

    // =============================================================
    //                           ERRORS
    // =============================================================

    error InvalidVerifier();
    error InvalidProgramVKey();
    error ProofVerificationFailed();
    error ProofAlreadyUsed();
    error CredentialAlreadyVerified();
    error CredentialNotFound();
    error CredentialExpired();
    error InvalidPublicValues();

    // =============================================================
    //                        CONSTRUCTOR
    // =============================================================

    /**
     * @notice Constructs the SP1CredentialVerifier
     * @param _sp1Verifier Address of the SP1 verifier contract
     * @param _programVKey The verification key for the SP1 program
     */
    constructor(
        address _sp1Verifier,
        bytes32 _programVKey
    ) Ownable(msg.sender) {
        if (_sp1Verifier == address(0)) revert InvalidVerifier();
        if (_programVKey == bytes32(0)) revert InvalidProgramVKey();

        sp1Verifier = ISP1Verifier(_sp1Verifier);
        programVKey = _programVKey;
    }

    // =============================================================
    //                    CONFIGURATION
    // =============================================================

    /**
     * @notice Updates the SP1 verifier contract address
     * @param _newVerifier The new verifier address
     */
    function updateSP1Verifier(address _newVerifier) external onlyOwner {
        if (_newVerifier == address(0)) revert InvalidVerifier();

        address oldVerifier = address(sp1Verifier);
        sp1Verifier = ISP1Verifier(_newVerifier);

        emit SP1VerifierUpdated(oldVerifier, _newVerifier);
    }

    /**
     * @notice Updates the program verification key
     * @param _newVKey The new verification key
     */
    function updateProgramVKey(bytes32 _newVKey) external onlyOwner {
        if (_newVKey == bytes32(0)) revert InvalidProgramVKey();

        bytes32 oldKey = programVKey;
        programVKey = _newVKey;

        emit ProgramVKeyUpdated(oldKey, _newVKey);
    }

    /**
     * @notice Sets the credential expiration time
     * @param _expirationTime Expiration time in seconds (0 for no expiration)
     */
    function setExpirationTime(uint256 _expirationTime) external onlyOwner {
        uint256 oldTime = credentialExpirationTime;
        credentialExpirationTime = _expirationTime;

        emit ExpirationTimeUpdated(oldTime, _expirationTime);
    }

    // =============================================================
    //                    VERIFICATION
    // =============================================================

    /**
     * @notice Verifies a credential using an SP1 zero-knowledge proof
     * @param publicValues The public values from the proof (encoded credential data)
     * @param proofBytes The SP1 proof bytes
     * @return credentialHash The hash of the verified credential
     */
    function verifyCredential(
        bytes calldata publicValues,
        bytes calldata proofBytes
    ) external nonReentrant returns (bytes32 credentialHash) {
        // Compute proof hash to prevent replay
        bytes32 proofHash = keccak256(abi.encodePacked(publicValues, proofBytes));
        if (usedProofs[proofHash]) revert ProofAlreadyUsed();

        // Verify the proof using SP1 verifier
        try sp1Verifier.verifyProof(programVKey, publicValues, proofBytes) {
            // Proof is valid
        } catch {
            revert ProofVerificationFailed();
        }

        // Decode public values
        // Expected format: (address subject, uint256 credentialType, bytes32 credentialHash, uint256 issuedAt, uint256 expiresAt)
        (
            address subject,
            uint256 credentialType,
            bytes32 credHash,
            uint256 issuedAt,
            uint256 expiresAt
        ) = abi.decode(publicValues, (address, uint256, bytes32, uint256, uint256));

        if (subject == address(0)) revert InvalidPublicValues();
        if (verifiedCredentials[credHash]) revert CredentialAlreadyVerified();

        // Mark proof as used
        usedProofs[proofHash] = true;

        // Store verified credential
        verifiedCredentials[credHash] = true;
        credentialTimestamps[credHash] = block.timestamp;
        userCredentials[subject].push(credHash);

        credentials[credHash] = VerifiedCredential({
            credentialHash: credHash,
            subject: subject,
            credentialType: credentialType,
            issuedAt: issuedAt,
            expiresAt: expiresAt,
            isValid: true
        });

        emit CredentialVerified(credHash, subject, credentialType, block.timestamp);

        return credHash;
    }

    /**
     * @notice Verifies a credential with a custom verification key
     * @param customVKey Custom verification key
     * @param publicValues The public values from the proof
     * @param proofBytes The SP1 proof bytes
     * @return credentialHash The hash of the verified credential
     */
    function verifyCredentialWithCustomKey(
        bytes32 customVKey,
        bytes calldata publicValues,
        bytes calldata proofBytes
    ) external nonReentrant returns (bytes32 credentialHash) {
        if (customVKey == bytes32(0)) revert InvalidProgramVKey();

        bytes32 proofHash = keccak256(abi.encodePacked(customVKey, publicValues, proofBytes));
        if (usedProofs[proofHash]) revert ProofAlreadyUsed();

        try sp1Verifier.verifyProof(customVKey, publicValues, proofBytes) {
            // Proof is valid
        } catch {
            revert ProofVerificationFailed();
        }

        // Decode and store (same as verifyCredential)
        (
            address subject,
            uint256 credentialType,
            bytes32 credHash,
            uint256 issuedAt,
            uint256 expiresAt
        ) = abi.decode(publicValues, (address, uint256, bytes32, uint256, uint256));

        if (subject == address(0)) revert InvalidPublicValues();
        if (verifiedCredentials[credHash]) revert CredentialAlreadyVerified();

        usedProofs[proofHash] = true;
        verifiedCredentials[credHash] = true;
        credentialTimestamps[credHash] = block.timestamp;
        userCredentials[subject].push(credHash);

        credentials[credHash] = VerifiedCredential({
            credentialHash: credHash,
            subject: subject,
            credentialType: credentialType,
            issuedAt: issuedAt,
            expiresAt: expiresAt,
            isValid: true
        });

        emit CredentialVerified(credHash, subject, credentialType, block.timestamp);

        return credHash;
    }

    /**
     * @notice Revokes a verified credential
     * @param credentialHash The hash of the credential to revoke
     */
    function revokeCredential(bytes32 credentialHash) external onlyOwner {
        if (!verifiedCredentials[credentialHash]) revert CredentialNotFound();

        verifiedCredentials[credentialHash] = false;
        credentials[credentialHash].isValid = false;

        emit CredentialRevoked(credentialHash, msg.sender);
    }

    // =============================================================
    //                    VIEW FUNCTIONS
    // =============================================================

    /**
     * @notice Checks if a credential is valid (verified and not expired)
     * @param credentialHash The credential hash to check
     * @return valid Whether the credential is valid
     */
    function isCredentialValid(bytes32 credentialHash) external view returns (bool valid) {
        if (!verifiedCredentials[credentialHash]) {
            return false;
        }

        VerifiedCredential memory cred = credentials[credentialHash];
        if (!cred.isValid) {
            return false;
        }

        // Check expiration
        if (cred.expiresAt > 0 && block.timestamp > cred.expiresAt) {
            return false;
        }

        // Check global expiration time
        if (credentialExpirationTime > 0) {
            if (block.timestamp > credentialTimestamps[credentialHash] + credentialExpirationTime) {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice Gets all credential hashes for a user
     * @param user The user address
     * @return credentialHashes Array of credential hashes
     */
    function getUserCredentials(address user) external view returns (bytes32[] memory) {
        return userCredentials[user];
    }

    /**
     * @notice Gets the credential details
     * @param credentialHash The credential hash
     * @return credential The verified credential data
     */
    function getCredential(bytes32 credentialHash) external view returns (VerifiedCredential memory) {
        return credentials[credentialHash];
    }

    /**
     * @notice Checks if a user has any valid credentials of a specific type
     * @param user The user address
     * @param credentialType The credential type to check
     * @return hasCredential Whether the user has a valid credential of that type
     */
    function hasValidCredentialOfType(
        address user,
        uint256 credentialType
    ) external view returns (bool hasCredential) {
        bytes32[] memory userCreds = userCredentials[user];

        for (uint256 i = 0; i < userCreds.length; i++) {
            VerifiedCredential memory cred = credentials[userCreds[i]];

            if (cred.credentialType == credentialType && cred.isValid) {
                // Check expiration
                if (cred.expiresAt == 0 || block.timestamp <= cred.expiresAt) {
                    return true;
                }
            }
        }

        return false;
    }
}
