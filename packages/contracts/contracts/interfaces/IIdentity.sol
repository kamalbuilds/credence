// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

/**
 * @title IIdentity
 * @notice Interface for OnchainID Identity contracts (ERC-734/735)
 * @dev Defines key and claim management for identity contracts
 */
interface IIdentity {
    // ERC-734 Key Events
    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Approved(uint256 indexed executionId, bool approved);

    // ERC-735 Claim Events
    event ClaimRequested(uint256 indexed claimRequestId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimAdded(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimRemoved(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimChanged(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    // Key Management (ERC-734)
    function getKey(bytes32 _key) external view returns (uint256[] memory purposes, uint256 keyType, bytes32 key);
    function keyHasPurpose(bytes32 _key, uint256 _purpose) external view returns (bool exists);
    function getKeysByPurpose(uint256 _purpose) external view returns (bytes32[] memory keys);
    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) external returns (bool success);
    function removeKey(bytes32 _key, uint256 _purpose) external returns (bool success);

    // Execution (ERC-734)
    function execute(address _to, uint256 _value, bytes calldata _data) external payable returns (uint256 executionId);
    function approve(uint256 _id, bool _approve) external returns (bool success);

    // Claim Management (ERC-735)
    function getClaim(bytes32 _claimId) external view returns (
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes memory signature,
        bytes memory data,
        string memory uri
    );
    function getClaimIdsByTopic(uint256 _topic) external view returns (bytes32[] memory claimIds);
    function addClaim(
        uint256 _topic,
        uint256 _scheme,
        address _issuer,
        bytes calldata _signature,
        bytes calldata _data,
        string calldata _uri
    ) external returns (bytes32 claimRequestId);
    function removeClaim(bytes32 _claimId) external returns (bool success);
}
