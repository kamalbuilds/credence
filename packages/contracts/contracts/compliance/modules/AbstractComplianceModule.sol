// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IComplianceModule.sol";
import "../../interfaces/IModularCompliance.sol";

/**
 * @title AbstractComplianceModule
 * @notice Base contract for compliance modules in the ERC-3643 T-REX framework
 * @dev Provides common functionality for all compliance modules
 *      Based on T-REX AbstractModule pattern from Tokeny
 */
abstract contract AbstractComplianceModule is Ownable, IComplianceModule {
    // =============================================================
    //                           STORAGE
    // =============================================================

    /// @notice Mapping of bound compliance contracts
    mapping(address => bool) private _boundCompliance;

    // =============================================================
    //                          MODIFIERS
    // =============================================================

    /**
     * @notice Ensures caller is a bound compliance contract
     */
    modifier onlyBoundCompliance() {
        require(_boundCompliance[msg.sender], "AbstractComplianceModule: caller is not bound compliance");
        _;
    }

    // =============================================================
    //                        CONSTRUCTOR
    // =============================================================

    constructor() Ownable(msg.sender) {}

    // =============================================================
    //                   COMPLIANCE BINDING
    // =============================================================

    /**
     * @inheritdoc IComplianceModule
     */
    function bindCompliance(address _compliance) external override {
        require(_compliance != address(0), "AbstractComplianceModule: invalid compliance");
        require(!_boundCompliance[_compliance], "AbstractComplianceModule: already bound");

        // For non-plug-and-play modules, check if compliance is suitable
        if (!this.isPlugAndPlay()) {
            require(canComplianceBind(_compliance), "AbstractComplianceModule: compliance not suitable");
        }

        _boundCompliance[_compliance] = true;
        emit ComplianceBound(_compliance);
    }

    /**
     * @inheritdoc IComplianceModule
     */
    function unbindCompliance(address _compliance) external override {
        require(_boundCompliance[_compliance], "AbstractComplianceModule: not bound");

        _boundCompliance[_compliance] = false;
        emit ComplianceUnbound(_compliance);
    }

    /**
     * @inheritdoc IComplianceModule
     */
    function isComplianceBound(address _compliance) external view override returns (bool) {
        return _boundCompliance[_compliance];
    }

    /**
     * @inheritdoc IComplianceModule
     * @dev Default: any compliance can bind (plug and play)
     *      Override in child contracts for specific requirements
     */
    function canComplianceBind(address /*_compliance*/) public view virtual override returns (bool) {
        return true;
    }

    /**
     * @inheritdoc IComplianceModule
     * @dev Default: plug and play. Override if module requires pre-configuration
     */
    function isPlugAndPlay() public pure virtual override returns (bool) {
        return true;
    }

    // =============================================================
    //                    DEFAULT IMPLEMENTATIONS
    // =============================================================

    /**
     * @inheritdoc IComplianceModule
     * @dev Default implementation - override in child contracts
     */
    function moduleTransferAction(
        address _from,
        address _to,
        uint256 _amount,
        address _compliance
    ) external virtual override onlyBoundCompliance {
        // Default: no action - override if module needs to track transfers
    }

    /**
     * @inheritdoc IComplianceModule
     * @dev Default implementation - override in child contracts
     */
    function moduleMintAction(
        address _to,
        uint256 _amount,
        address _compliance
    ) external virtual override onlyBoundCompliance {
        // Default: no action - override if module needs to track mints
    }

    /**
     * @inheritdoc IComplianceModule
     * @dev Default implementation - override in child contracts
     */
    function moduleBurnAction(
        address _from,
        uint256 _amount,
        address _compliance
    ) external virtual override onlyBoundCompliance {
        // Default: no action - override if module needs to track burns
    }

    // =============================================================
    //                    HELPER FUNCTIONS
    // =============================================================

    /**
     * @notice Gets the token bound to a compliance contract
     * @param _compliance The compliance contract
     * @return The bound token address
     */
    function _getToken(address _compliance) internal view returns (address) {
        return IModularCompliance(_compliance).getTokenBound();
    }
}
