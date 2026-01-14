// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

/**
 * @title IModularCompliance
 * @notice Interface for the ERC-3643 Modular Compliance
 * @dev Manages compliance modules for token transfer restrictions
 */
interface IModularCompliance {
    event TokenBound(address indexed token);
    event TokenUnbound(address indexed token);
    event ModuleAdded(address indexed module);
    event ModuleRemoved(address indexed module);

    /**
     * @notice Binds a token to this compliance contract
     * @param _token The token address to bind
     */
    function bindToken(address _token) external;

    /**
     * @notice Unbinds a token from this compliance contract
     * @param _token The token address to unbind
     */
    function unbindToken(address _token) external;

    /**
     * @notice Adds a compliance module
     * @param _module The module address to add
     */
    function addModule(address _module) external;

    /**
     * @notice Removes a compliance module
     * @param _module The module address to remove
     */
    function removeModule(address _module) external;

    /**
     * @notice Calls a function on a module
     * @param _module The module to call
     * @param _callData The call data
     */
    function callModuleFunction(bytes calldata _callData, address _module) external;

    /**
     * @notice Checks if a transfer is allowed
     * @param _from Sender address
     * @param _to Receiver address
     * @param _amount Transfer amount
     * @return allowed Whether the transfer is allowed
     */
    function canTransfer(address _from, address _to, uint256 _amount) external view returns (bool allowed);

    /**
     * @notice Called after a transfer to update module state
     * @param _from Sender address
     * @param _to Receiver address
     * @param _amount Transfer amount
     */
    function transferred(address _from, address _to, uint256 _amount) external;

    /**
     * @notice Called after tokens are created
     * @param _to Receiver address
     * @param _amount Amount created
     */
    function created(address _to, uint256 _amount) external;

    /**
     * @notice Called after tokens are destroyed
     * @param _from Address tokens were burned from
     * @param _amount Amount destroyed
     */
    function destroyed(address _from, uint256 _amount) external;

    /**
     * @notice Gets all modules
     * @return modules Array of module addresses
     */
    function getModules() external view returns (address[] memory modules);

    /**
     * @notice Gets the bound token
     * @return token The bound token address
     */
    function getTokenBound() external view returns (address token);

    /**
     * @notice Checks if a module is bound
     * @param _module The module to check
     * @return bound Whether the module is bound
     */
    function isModuleBound(address _module) external view returns (bool bound);
}
