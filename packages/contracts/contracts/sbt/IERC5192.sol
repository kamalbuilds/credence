// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IERC5192
 * @notice Interface for EIP-5192 Minimal Soulbound NFTs
 * @dev See https://eips.ethereum.org/EIPS/eip-5192
 */
interface IERC5192 {
    /**
     * @notice Emitted when the locking status is changed to locked
     * @param tokenId The identifier for a token
     */
    event Locked(uint256 tokenId);

    /**
     * @notice Emitted when the locking status is changed to unlocked
     * @param tokenId The identifier for a token
     */
    event Unlocked(uint256 tokenId);

    /**
     * @notice Returns the locking status of a Soulbound Token
     * @dev SBTs assigned to zero address are considered invalid, and queries
     * about them do throw
     * @param tokenId The identifier for a token
     * @return locked Whether the token is locked
     */
    function locked(uint256 tokenId) external view returns (bool);
}
