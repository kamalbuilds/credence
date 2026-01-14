// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "./IIdentity.sol";

/**
 * @title IIdentityRegistryStorage
 * @notice Interface for the storage contract of the Identity Registry
 * @dev Separates storage from logic for upgradeability
 */
interface IIdentityRegistryStorage {
    event IdentityStored(address indexed investorAddress, IIdentity indexed identity);
    event IdentityUnstored(address indexed investorAddress, IIdentity indexed identity);
    event IdentityModified(IIdentity indexed oldIdentity, IIdentity indexed newIdentity);
    event CountryModified(address indexed investorAddress, uint16 indexed country);
    event IdentityRegistryBound(address indexed identityRegistry);
    event IdentityRegistryUnbound(address indexed identityRegistry);

    /**
     * @notice Adds an identity to storage
     * @param _userAddress The investor's wallet address
     * @param _identity The identity contract
     * @param _country The country code
     */
    function addIdentityToStorage(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) external;

    /**
     * @notice Removes an identity from storage
     * @param _userAddress The investor's wallet address
     */
    function removeIdentityFromStorage(address _userAddress) external;

    /**
     * @notice Modifies an identity in storage
     * @param _userAddress The investor's wallet address
     * @param _identity The new identity
     */
    function modifyStoredIdentity(address _userAddress, IIdentity _identity) external;

    /**
     * @notice Modifies an investor's country in storage
     * @param _userAddress The investor's wallet address
     * @param _country The new country code
     */
    function modifyStoredInvestorCountry(address _userAddress, uint16 _country) external;

    /**
     * @notice Binds an identity registry to this storage
     * @param _identityRegistry The identity registry to bind
     */
    function bindIdentityRegistry(address _identityRegistry) external;

    /**
     * @notice Unbinds an identity registry from this storage
     * @param _identityRegistry The identity registry to unbind
     */
    function unbindIdentityRegistry(address _identityRegistry) external;

    /**
     * @notice Gets the list of linked identity registries
     * @return registries Array of linked identity registries
     */
    function linkedIdentityRegistries() external view returns (address[] memory registries);

    /**
     * @notice Gets the stored identity for an address
     * @param _userAddress The investor's wallet address
     * @return identity The stored identity
     */
    function storedIdentity(address _userAddress) external view returns (IIdentity identity);

    /**
     * @notice Gets the stored country for an investor
     * @param _userAddress The investor's wallet address
     * @return country The stored country code
     */
    function storedInvestorCountry(address _userAddress) external view returns (uint16 country);
}
