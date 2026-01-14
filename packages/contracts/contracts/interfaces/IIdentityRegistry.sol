// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "./IIdentity.sol";
import "./IClaimTopicsRegistry.sol";
import "./ITrustedIssuersRegistry.sol";
import "./IIdentityRegistryStorage.sol";

/**
 * @title IIdentityRegistry
 * @notice Interface for the ERC-3643 Identity Registry
 * @dev Manages the relationship between wallet addresses and OnchainID identities
 */
interface IIdentityRegistry {
    event IdentityRegistered(address indexed investorAddress, IIdentity indexed identity);
    event IdentityRemoved(address indexed investorAddress, IIdentity indexed identity);
    event IdentityUpdated(IIdentity indexed oldIdentity, IIdentity indexed newIdentity);
    event CountryUpdated(address indexed investorAddress, uint16 indexed country);
    event ClaimTopicsRegistrySet(address indexed claimTopicsRegistry);
    event TrustedIssuersRegistrySet(address indexed trustedIssuersRegistry);
    event IdentityStorageSet(address indexed identityStorage);

    /**
     * @notice Registers an identity for an investor
     * @param _userAddress The investor's wallet address
     * @param _identity The identity contract
     * @param _country The investor's country code
     */
    function registerIdentity(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) external;

    /**
     * @notice Registers multiple identities in batch
     * @param _userAddresses Array of investor addresses
     * @param _identities Array of identity contracts
     * @param _countries Array of country codes
     */
    function batchRegisterIdentity(
        address[] calldata _userAddresses,
        IIdentity[] calldata _identities,
        uint16[] calldata _countries
    ) external;

    /**
     * @notice Deletes an identity from the registry
     * @param _userAddress The investor's wallet address
     */
    function deleteIdentity(address _userAddress) external;

    /**
     * @notice Updates an identity
     * @param _userAddress The investor's wallet address
     * @param _identity The new identity contract
     */
    function updateIdentity(address _userAddress, IIdentity _identity) external;

    /**
     * @notice Updates an investor's country
     * @param _userAddress The investor's wallet address
     * @param _country The new country code
     */
    function updateCountry(address _userAddress, uint16 _country) external;

    /**
     * @notice Sets the claim topics registry
     * @param _claimTopicsRegistry The claim topics registry address
     */
    function setClaimTopicsRegistry(address _claimTopicsRegistry) external;

    /**
     * @notice Sets the trusted issuers registry
     * @param _trustedIssuersRegistry The trusted issuers registry address
     */
    function setTrustedIssuersRegistry(address _trustedIssuersRegistry) external;

    /**
     * @notice Sets the identity storage
     * @param _identityStorage The identity storage address
     */
    function setIdentityStorage(address _identityStorage) external;

    /**
     * @notice Checks if an investor is verified
     * @param _userAddress The investor's wallet address
     * @return verified Whether the investor is verified
     */
    function isVerified(address _userAddress) external view returns (bool verified);

    /**
     * @notice Gets the identity for an address
     * @param _userAddress The investor's wallet address
     * @return identity The identity contract
     */
    function identity(address _userAddress) external view returns (IIdentity identity);

    /**
     * @notice Gets the country for an investor
     * @param _userAddress The investor's wallet address
     * @return country The country code
     */
    function investorCountry(address _userAddress) external view returns (uint16 country);

    /**
     * @notice Returns the trusted issuers registry
     * @return registry The trusted issuers registry
     */
    function issuersRegistry() external view returns (ITrustedIssuersRegistry registry);

    /**
     * @notice Returns the claim topics registry
     * @return registry The claim topics registry
     */
    function topicsRegistry() external view returns (IClaimTopicsRegistry registry);

    /**
     * @notice Returns the identity storage
     * @return storage_ The identity storage
     */
    function identityStorage() external view returns (IIdentityRegistryStorage storage_);

    /**
     * @notice Checks if an address contains an identity
     * @param _userAddress The address to check
     * @return exists Whether the identity exists
     */
    function contains(address _userAddress) external view returns (bool exists);
}
