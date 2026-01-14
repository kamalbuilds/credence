// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IIdentityRegistryStorage.sol";
import "../interfaces/IIdentity.sol";

/**
 * @title IdentityRegistryStorage
 * @notice Storage contract for identity registry data, separated for upgradeability
 * @dev Part of the ERC-3643 T-REX protocol
 */
contract IdentityRegistryStorage is Ownable, IIdentityRegistryStorage {
    // =============================================================
    //                           STORAGE
    // =============================================================

    /// @notice Mapping from user address to identity
    mapping(address => IIdentity) private _identities;

    /// @notice Mapping from user address to country code
    mapping(address => uint16) private _countries;

    /// @notice Array of linked identity registries
    address[] private _identityRegistries;

    /// @notice Mapping to check if a registry is linked
    mapping(address => bool) private _isLinked;

    // =============================================================
    //                          MODIFIERS
    // =============================================================

    /**
     * @notice Ensures caller is a linked identity registry
     */
    modifier onlyLinkedRegistry() {
        require(_isLinked[msg.sender], "IdentityRegistryStorage: caller is not a linked registry");
        _;
    }

    // =============================================================
    //                        CONSTRUCTOR
    // =============================================================

    constructor() Ownable(msg.sender) {}

    // =============================================================
    //                    REGISTRY MANAGEMENT
    // =============================================================

    /**
     * @inheritdoc IIdentityRegistryStorage
     */
    function bindIdentityRegistry(address _identityRegistry) external override onlyOwner {
        require(_identityRegistry != address(0), "IdentityRegistryStorage: invalid registry");
        require(!_isLinked[_identityRegistry], "IdentityRegistryStorage: already linked");

        _identityRegistries.push(_identityRegistry);
        _isLinked[_identityRegistry] = true;

        emit IdentityRegistryBound(_identityRegistry);
    }

    /**
     * @inheritdoc IIdentityRegistryStorage
     */
    function unbindIdentityRegistry(address _identityRegistry) external override onlyOwner {
        require(_isLinked[_identityRegistry], "IdentityRegistryStorage: not linked");

        for (uint256 i = 0; i < _identityRegistries.length; i++) {
            if (_identityRegistries[i] == _identityRegistry) {
                _identityRegistries[i] = _identityRegistries[_identityRegistries.length - 1];
                _identityRegistries.pop();
                break;
            }
        }

        _isLinked[_identityRegistry] = false;

        emit IdentityRegistryUnbound(_identityRegistry);
    }

    /**
     * @inheritdoc IIdentityRegistryStorage
     */
    function linkedIdentityRegistries() external view override returns (address[] memory) {
        return _identityRegistries;
    }

    // =============================================================
    //                   IDENTITY MANAGEMENT
    // =============================================================

    /**
     * @inheritdoc IIdentityRegistryStorage
     */
    function addIdentityToStorage(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) external override onlyLinkedRegistry {
        require(_userAddress != address(0), "IdentityRegistryStorage: invalid user address");
        require(address(_identity) != address(0), "IdentityRegistryStorage: invalid identity");
        require(address(_identities[_userAddress]) == address(0), "IdentityRegistryStorage: identity already exists");

        _identities[_userAddress] = _identity;
        _countries[_userAddress] = _country;

        emit IdentityStored(_userAddress, _identity);
    }

    /**
     * @inheritdoc IIdentityRegistryStorage
     */
    function removeIdentityFromStorage(address _userAddress) external override onlyLinkedRegistry {
        require(address(_identities[_userAddress]) != address(0), "IdentityRegistryStorage: identity not found");

        IIdentity oldIdentity = _identities[_userAddress];
        delete _identities[_userAddress];
        delete _countries[_userAddress];

        emit IdentityUnstored(_userAddress, oldIdentity);
    }

    /**
     * @inheritdoc IIdentityRegistryStorage
     */
    function modifyStoredIdentity(
        address _userAddress,
        IIdentity _identity
    ) external override onlyLinkedRegistry {
        require(address(_identities[_userAddress]) != address(0), "IdentityRegistryStorage: identity not found");
        require(address(_identity) != address(0), "IdentityRegistryStorage: invalid identity");

        IIdentity oldIdentity = _identities[_userAddress];
        _identities[_userAddress] = _identity;

        emit IdentityModified(oldIdentity, _identity);
    }

    /**
     * @inheritdoc IIdentityRegistryStorage
     */
    function modifyStoredInvestorCountry(
        address _userAddress,
        uint16 _country
    ) external override onlyLinkedRegistry {
        require(address(_identities[_userAddress]) != address(0), "IdentityRegistryStorage: identity not found");

        _countries[_userAddress] = _country;

        emit CountryModified(_userAddress, _country);
    }

    // =============================================================
    //                       VIEW FUNCTIONS
    // =============================================================

    /**
     * @inheritdoc IIdentityRegistryStorage
     */
    function storedIdentity(address _userAddress) external view override returns (IIdentity) {
        return _identities[_userAddress];
    }

    /**
     * @inheritdoc IIdentityRegistryStorage
     */
    function storedInvestorCountry(address _userAddress) external view override returns (uint16) {
        return _countries[_userAddress];
    }
}
