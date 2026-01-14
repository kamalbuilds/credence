// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "./AbstractComplianceModule.sol";
import "../../interfaces/IVerifiToken.sol";
import "../../interfaces/IIdentityRegistry.sol";

/**
 * @title CountryRestrictModule
 * @notice Compliance module that restricts transfers based on country codes
 * @dev Can be configured to either allow or block specific countries
 */
contract CountryRestrictModule is AbstractComplianceModule {
    // =============================================================
    //                           STORAGE
    // =============================================================

    /// @notice Mapping of compliance to restricted countries
    mapping(address => mapping(uint16 => bool)) private _restrictedCountries;

    /// @notice Mapping to track if a compliance uses allowlist mode
    mapping(address => bool) private _allowlistMode;

    // =============================================================
    //                           EVENTS
    // =============================================================

    event CountryRestricted(address indexed compliance, uint16 indexed country);
    event CountryUnrestricted(address indexed compliance, uint16 indexed country);
    event AllowlistModeSet(address indexed compliance, bool allowlistMode);

    // =============================================================
    //                        CONSTRUCTOR
    // =============================================================

    constructor() AbstractComplianceModule() {}

    // =============================================================
    //                    CONFIGURATION
    // =============================================================

    /**
     * @notice Sets whether the module uses allowlist mode
     * @param _compliance The compliance contract
     * @param _allowlist True for allowlist mode (only listed countries allowed), false for blocklist
     */
    function setAllowlistMode(address _compliance, bool _allowlist) external onlyOwner {
        _allowlistMode[_compliance] = _allowlist;
        emit AllowlistModeSet(_compliance, _allowlist);
    }

    /**
     * @notice Adds a country to the restricted list
     * @param _compliance The compliance contract
     * @param _country The country code to restrict
     */
    function addCountryRestriction(address _compliance, uint16 _country) external onlyOwner {
        require(!_restrictedCountries[_compliance][_country], "CountryRestrictModule: already restricted");
        _restrictedCountries[_compliance][_country] = true;
        emit CountryRestricted(_compliance, _country);
    }

    /**
     * @notice Removes a country from the restricted list
     * @param _compliance The compliance contract
     * @param _country The country code to unrestrict
     */
    function removeCountryRestriction(address _compliance, uint16 _country) external onlyOwner {
        require(_restrictedCountries[_compliance][_country], "CountryRestrictModule: not restricted");
        _restrictedCountries[_compliance][_country] = false;
        emit CountryUnrestricted(_compliance, _country);
    }

    /**
     * @notice Batch adds countries to the restricted list
     * @param _compliance The compliance contract
     * @param _countries Array of country codes to restrict
     */
    function batchAddCountryRestriction(address _compliance, uint16[] calldata _countries) external onlyOwner {
        for (uint256 i = 0; i < _countries.length; i++) {
            if (!_restrictedCountries[_compliance][_countries[i]]) {
                _restrictedCountries[_compliance][_countries[i]] = true;
                emit CountryRestricted(_compliance, _countries[i]);
            }
        }
    }

    /**
     * @notice Batch removes countries from the restricted list
     * @param _compliance The compliance contract
     * @param _countries Array of country codes to unrestrict
     */
    function batchRemoveCountryRestriction(address _compliance, uint16[] calldata _countries) external onlyOwner {
        for (uint256 i = 0; i < _countries.length; i++) {
            if (_restrictedCountries[_compliance][_countries[i]]) {
                _restrictedCountries[_compliance][_countries[i]] = false;
                emit CountryUnrestricted(_compliance, _countries[i]);
            }
        }
    }

    // =============================================================
    //                    COMPLIANCE CHECK
    // =============================================================

    /**
     * @inheritdoc IComplianceModule
     */
    function moduleCheck(
        address _from,
        address _to,
        uint256 /*_amount*/,
        address _compliance
    ) external view override returns (bool) {
        address token = _getToken(_compliance);
        IIdentityRegistry identityRegistry = IVerifiToken(token).identityRegistry();

        uint16 fromCountry = identityRegistry.investorCountry(_from);
        uint16 toCountry = identityRegistry.investorCountry(_to);

        if (_allowlistMode[_compliance]) {
            // Allowlist mode: both countries must be in the list
            return _restrictedCountries[_compliance][fromCountry] && _restrictedCountries[_compliance][toCountry];
        } else {
            // Blocklist mode: neither country can be in the list
            return !_restrictedCountries[_compliance][fromCountry] && !_restrictedCountries[_compliance][toCountry];
        }
    }

    // =============================================================
    //                    VIEW FUNCTIONS
    // =============================================================

    /**
     * @notice Checks if a country is restricted
     * @param _compliance The compliance contract
     * @param _country The country code
     * @return Whether the country is restricted
     */
    function isCountryRestricted(address _compliance, uint16 _country) external view returns (bool) {
        return _restrictedCountries[_compliance][_country];
    }

    /**
     * @notice Checks if allowlist mode is enabled
     * @param _compliance The compliance contract
     * @return Whether allowlist mode is enabled
     */
    function isAllowlistMode(address _compliance) external view returns (bool) {
        return _allowlistMode[_compliance];
    }

    /**
     * @inheritdoc IComplianceModule
     */
    function name() external pure override returns (string memory) {
        return "CountryRestrictModule";
    }
}
