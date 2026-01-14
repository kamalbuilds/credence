// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

/**
 * @title IComplianceModule
 * @notice Interface for compliance modules in the ERC-3643 T-REX framework
 * @dev Modules implement transfer restrictions and can track state
 *      Based on T-REX IModule interface from Tokeny
 */
interface IComplianceModule {
    // =============================================================
    //                           EVENTS
    // =============================================================

    /**
     * @notice Emitted when a compliance contract is bound to this module
     * @param compliance The compliance contract address
     */
    event ComplianceBound(address indexed compliance);

    /**
     * @notice Emitted when a compliance contract is unbound from this module
     * @param compliance The compliance contract address
     */
    event ComplianceUnbound(address indexed compliance);

    // =============================================================
    //                    COMPLIANCE BINDING
    // =============================================================

    /**
     * @notice Binds a compliance contract to this module
     * @dev Can only be called by the compliance contract itself through addModule
     *      The module cannot be already bound to the compliance
     * @param _compliance The compliance contract to bind
     */
    function bindCompliance(address _compliance) external;

    /**
     * @notice Unbinds a compliance contract from this module
     * @dev Can only be called by the compliance contract itself through removeModule
     * @param _compliance The compliance contract to unbind
     */
    function unbindCompliance(address _compliance) external;

    // =============================================================
    //                    MODULE ACTIONS
    // =============================================================

    /**
     * @notice Action performed during a transfer
     * @dev Used to update module variables upon transfer if required
     *      Can only be called by a bound compliance contract
     * @param _from Address of the transfer sender
     * @param _to Address of the transfer receiver
     * @param _amount Amount of tokens sent
     * @param _compliance The compliance contract
     */
    function moduleTransferAction(
        address _from,
        address _to,
        uint256 _amount,
        address _compliance
    ) external;

    /**
     * @notice Action performed during a mint
     * @dev Used to update module variables upon minting if required
     *      Can only be called by a bound compliance contract
     * @param _to Address receiving the minted tokens
     * @param _amount Amount of tokens minted
     * @param _compliance The compliance contract
     */
    function moduleMintAction(
        address _to,
        uint256 _amount,
        address _compliance
    ) external;

    /**
     * @notice Action performed during a burn
     * @dev Used to update module variables upon burning if required
     *      Can only be called by a bound compliance contract
     * @param _from Address tokens are burned from
     * @param _amount Amount of tokens burned
     * @param _compliance The compliance contract
     */
    function moduleBurnAction(
        address _from,
        uint256 _amount,
        address _compliance
    ) external;

    // =============================================================
    //                    COMPLIANCE CHECK
    // =============================================================

    /**
     * @notice Checks if a transfer is compliant according to this module
     * @dev Called by the compliance contract to check transfer validity
     * @param _from Sender address
     * @param _to Receiver address
     * @param _amount Transfer amount
     * @param _compliance The compliance contract making the check
     * @return True if the transfer is allowed, false otherwise
     */
    function moduleCheck(
        address _from,
        address _to,
        uint256 _amount,
        address _compliance
    ) external view returns (bool);

    // =============================================================
    //                    VIEW FUNCTIONS
    // =============================================================

    /**
     * @notice Checks if a compliance contract is bound to this module
     * @param _compliance The compliance contract to check
     * @return True if the compliance is bound
     */
    function isComplianceBound(address _compliance) external view returns (bool);

    /**
     * @notice Checks whether a compliance contract is suitable for binding
     * @dev Used by non-plug-and-play modules to validate binding requirements
     * @param _compliance The compliance contract to check
     * @return True if the compliance can be bound
     */
    function canComplianceBind(address _compliance) external view returns (bool);

    /**
     * @notice Returns whether this module is plug and play
     * @dev Plug and play modules can be bound without additional configuration
     *      Non-plug-and-play modules require canComplianceBind() check
     * @return True if the module is plug and play
     */
    function isPlugAndPlay() external pure returns (bool);

    /**
     * @notice Returns the name of the module
     * @return The module name as a string
     */
    function name() external pure returns (string memory);
}
