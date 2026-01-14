// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "../interfaces/IIdentity.sol";

/**
 * @title Identity
 * @notice OnchainID Identity contract implementing ERC-734 (Key Manager) and ERC-735 (Claim Holder)
 * @dev Core identity component for ERC-3643 T-REX compliant tokens
 *      Manages cryptographic keys and verifiable claims for investor identity
 */
contract Identity is IIdentity {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    /// @notice Key purpose: Management keys can add/remove other keys
    uint256 public constant MANAGEMENT_KEY = 1;

    /// @notice Key purpose: Action keys can execute calls
    uint256 public constant ACTION_KEY = 2;

    /// @notice Key purpose: Claim signer keys can sign claims
    uint256 public constant CLAIM_SIGNER_KEY = 3;

    /// @notice Key purpose: Encryption keys for encrypted communication
    uint256 public constant ENCRYPTION_KEY = 4;

    /// @notice Key type: ECDSA key
    uint256 public constant ECDSA_TYPE = 1;

    /// @notice Key type: RSA key
    uint256 public constant RSA_TYPE = 2;

    // =============================================================
    //                           STORAGE
    // =============================================================

    /// @notice Struct for storing key data
    struct Key {
        uint256[] purposes;
        uint256 keyType;
        bytes32 key;
    }

    /// @notice Struct for storing claim data
    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
        bytes signature;
        bytes data;
        string uri;
    }

    /// @notice Mapping of key hash to key data
    mapping(bytes32 => Key) private _keys;

    /// @notice Mapping of purpose to key hashes
    mapping(uint256 => bytes32[]) private _keysByPurpose;

    /// @notice Mapping of claim ID to claim data
    mapping(bytes32 => Claim) private _claims;

    /// @notice Mapping of topic to claim IDs
    mapping(uint256 => bytes32[]) private _claimsByTopic;

    /// @notice Execution nonce for replay protection
    uint256 private _executionNonce;

    /// @notice Execution requests
    mapping(uint256 => bool) private _executed;

    // =============================================================
    //                        CONSTRUCTOR
    // =============================================================

    /**
     * @notice Constructs the Identity contract
     * @param _initialManagementKey The initial management key (typically msg.sender's address hash)
     */
    constructor(address _initialManagementKey) {
        bytes32 keyHash = keccak256(abi.encodePacked(_initialManagementKey));

        _keys[keyHash].key = keyHash;
        _keys[keyHash].purposes.push(MANAGEMENT_KEY);
        _keys[keyHash].keyType = ECDSA_TYPE;
        _keysByPurpose[MANAGEMENT_KEY].push(keyHash);

        emit KeyAdded(keyHash, MANAGEMENT_KEY, ECDSA_TYPE);
    }

    // =============================================================
    //                      KEY MANAGEMENT
    // =============================================================

    /**
     * @inheritdoc IIdentity
     */
    function getKey(bytes32 _key) external view override returns (
        uint256[] memory purposes,
        uint256 keyType,
        bytes32 key
    ) {
        return (_keys[_key].purposes, _keys[_key].keyType, _keys[_key].key);
    }

    /**
     * @inheritdoc IIdentity
     */
    function keyHasPurpose(bytes32 _key, uint256 _purpose) public view override returns (bool) {
        if (_keys[_key].key == bytes32(0)) return false;

        uint256[] memory purposes = _keys[_key].purposes;
        for (uint256 i = 0; i < purposes.length; i++) {
            if (purposes[i] == _purpose) {
                return true;
            }
        }
        return false;
    }

    /**
     * @inheritdoc IIdentity
     */
    function getKeysByPurpose(uint256 _purpose) external view override returns (bytes32[] memory) {
        return _keysByPurpose[_purpose];
    }

    /**
     * @inheritdoc IIdentity
     */
    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) external override returns (bool) {
        require(
            keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), MANAGEMENT_KEY),
            "Identity: sender does not have management key"
        );
        require(_keys[_key].key != _key, "Identity: key already exists");

        _keys[_key].key = _key;
        _keys[_key].purposes.push(_purpose);
        _keys[_key].keyType = _keyType;
        _keysByPurpose[_purpose].push(_key);

        emit KeyAdded(_key, _purpose, _keyType);
        return true;
    }

    /**
     * @inheritdoc IIdentity
     */
    function removeKey(bytes32 _key, uint256 _purpose) external override returns (bool) {
        require(
            keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), MANAGEMENT_KEY),
            "Identity: sender does not have management key"
        );
        require(_keys[_key].key == _key, "Identity: key does not exist");

        // Remove purpose from key
        uint256[] storage purposes = _keys[_key].purposes;
        for (uint256 i = 0; i < purposes.length; i++) {
            if (purposes[i] == _purpose) {
                purposes[i] = purposes[purposes.length - 1];
                purposes.pop();
                break;
            }
        }

        // Remove key from purpose list
        bytes32[] storage keyList = _keysByPurpose[_purpose];
        for (uint256 i = 0; i < keyList.length; i++) {
            if (keyList[i] == _key) {
                keyList[i] = keyList[keyList.length - 1];
                keyList.pop();
                break;
            }
        }

        uint256 keyType = _keys[_key].keyType;

        // If no more purposes, delete the key entirely
        if (_keys[_key].purposes.length == 0) {
            delete _keys[_key];
        }

        emit KeyRemoved(_key, _purpose, keyType);
        return true;
    }

    // =============================================================
    //                        EXECUTION
    // =============================================================

    /**
     * @inheritdoc IIdentity
     */
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external payable override returns (uint256 executionId) {
        require(
            keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), ACTION_KEY) ||
            keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), MANAGEMENT_KEY),
            "Identity: sender does not have action key"
        );

        executionId = _executionNonce++;

        emit ExecutionRequested(executionId, _to, _value, _data);

        (bool success, ) = _to.call{value: _value}(_data);
        require(success, "Identity: execution failed");

        _executed[executionId] = true;
        emit Executed(executionId, _to, _value, _data);

        return executionId;
    }

    /**
     * @inheritdoc IIdentity
     */
    function approve(uint256 _id, bool _approve) external override returns (bool) {
        require(
            keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), MANAGEMENT_KEY),
            "Identity: sender does not have management key"
        );

        emit Approved(_id, _approve);
        return true;
    }

    // =============================================================
    //                      CLAIM MANAGEMENT
    // =============================================================

    /**
     * @inheritdoc IIdentity
     */
    function getClaim(bytes32 _claimId) external view override returns (
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes memory signature,
        bytes memory data,
        string memory uri
    ) {
        Claim memory claim = _claims[_claimId];
        return (claim.topic, claim.scheme, claim.issuer, claim.signature, claim.data, claim.uri);
    }

    /**
     * @inheritdoc IIdentity
     */
    function getClaimIdsByTopic(uint256 _topic) external view override returns (bytes32[] memory) {
        return _claimsByTopic[_topic];
    }

    /**
     * @inheritdoc IIdentity
     */
    function addClaim(
        uint256 _topic,
        uint256 _scheme,
        address _issuer,
        bytes calldata _signature,
        bytes calldata _data,
        string calldata _uri
    ) external override returns (bytes32 claimRequestId) {
        // Only management keys or the issuer can add claims
        require(
            keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), MANAGEMENT_KEY) ||
            msg.sender == _issuer,
            "Identity: sender cannot add claims"
        );

        bytes32 claimId = keccak256(abi.encodePacked(_issuer, _topic));

        // Check if claim already exists
        if (_claims[claimId].issuer != address(0)) {
            // Update existing claim
            _claims[claimId] = Claim({
                topic: _topic,
                scheme: _scheme,
                issuer: _issuer,
                signature: _signature,
                data: _data,
                uri: _uri
            });

            emit ClaimChanged(claimId, _topic, _scheme, _issuer, _signature, _data, _uri);
        } else {
            // Add new claim
            _claims[claimId] = Claim({
                topic: _topic,
                scheme: _scheme,
                issuer: _issuer,
                signature: _signature,
                data: _data,
                uri: _uri
            });

            _claimsByTopic[_topic].push(claimId);

            emit ClaimAdded(claimId, _topic, _scheme, _issuer, _signature, _data, _uri);
        }

        return claimId;
    }

    /**
     * @inheritdoc IIdentity
     */
    function removeClaim(bytes32 _claimId) external override returns (bool) {
        Claim memory claim = _claims[_claimId];
        require(claim.issuer != address(0), "Identity: claim does not exist");

        // Only management keys or the original issuer can remove claims
        require(
            keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), MANAGEMENT_KEY) ||
            msg.sender == claim.issuer,
            "Identity: sender cannot remove claim"
        );

        // Remove from topic list
        bytes32[] storage topicClaims = _claimsByTopic[claim.topic];
        for (uint256 i = 0; i < topicClaims.length; i++) {
            if (topicClaims[i] == _claimId) {
                topicClaims[i] = topicClaims[topicClaims.length - 1];
                topicClaims.pop();
                break;
            }
        }

        emit ClaimRemoved(
            _claimId,
            claim.topic,
            claim.scheme,
            claim.issuer,
            claim.signature,
            claim.data,
            claim.uri
        );

        delete _claims[_claimId];

        return true;
    }

    // =============================================================
    //                      HELPER FUNCTIONS
    // =============================================================

    /**
     * @notice Allows the contract to receive ETH
     */
    receive() external payable {}

    /**
     * @notice Returns the execution nonce
     * @return The current execution nonce
     */
    function getExecutionNonce() external view returns (uint256) {
        return _executionNonce;
    }
}
