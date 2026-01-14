// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IModularCompliance.sol";
import "../interfaces/IComplianceModule.sol";

/**
 * @title ModularCompliance
 * @notice Manages compliance modules for token transfer restrictions
 * @dev Core compliance component of ERC-3643 T-REX protocol
 */
contract ModularCompliance is Ownable, IModularCompliance {
    // =============================================================
    //                           STORAGE
    // =============================================================

    /// @notice Address of the bound token
    address private _tokenBound;

    /// @notice Array of compliance modules
    address[] private _modules;

    /// @notice Mapping to check if a module is bound
    mapping(address => bool) private _moduleBound;

    /// @notice Maximum number of modules allowed
    uint256 public constant MAX_MODULES = 25;

    // =============================================================
    //                          MODIFIERS
    // =============================================================

    /**
     * @notice Ensures caller is the bound token
     */
    modifier onlyToken() {
        require(msg.sender == _tokenBound, "ModularCompliance: caller is not the token");
        _;
    }

    // =============================================================
    //                        CONSTRUCTOR
    // =============================================================

    constructor() Ownable(msg.sender) {}

    // =============================================================
    //                     TOKEN BINDING
    // =============================================================

    /**
     * @inheritdoc IModularCompliance
     */
    function bindToken(address _token) external override onlyOwner {
        require(_token != address(0), "ModularCompliance: invalid token");
        require(_tokenBound == address(0), "ModularCompliance: token already bound");

        _tokenBound = _token;
        emit TokenBound(_token);
    }

    /**
     * @inheritdoc IModularCompliance
     */
    function unbindToken(address _token) external override onlyOwner {
        require(_token == _tokenBound, "ModularCompliance: token not bound");

        _tokenBound = address(0);
        emit TokenUnbound(_token);
    }

    /**
     * @inheritdoc IModularCompliance
     */
    function getTokenBound() external view override returns (address) {
        return _tokenBound;
    }

    // =============================================================
    //                    MODULE MANAGEMENT
    // =============================================================

    /**
     * @inheritdoc IModularCompliance
     */
    function addModule(address _module) external override onlyOwner {
        require(_module != address(0), "ModularCompliance: invalid module");
        require(!_moduleBound[_module], "ModularCompliance: module already bound");
        require(_modules.length < MAX_MODULES, "ModularCompliance: max modules reached");

        _modules.push(_module);
        _moduleBound[_module] = true;

        // Bind this compliance to the module
        IComplianceModule(_module).bindCompliance(address(this));

        emit ModuleAdded(_module);
    }

    /**
     * @inheritdoc IModularCompliance
     */
    function removeModule(address _module) external override onlyOwner {
        require(_moduleBound[_module], "ModularCompliance: module not bound");

        // Unbind from module
        IComplianceModule(_module).unbindCompliance(address(this));

        // Remove from array
        for (uint256 i = 0; i < _modules.length; i++) {
            if (_modules[i] == _module) {
                _modules[i] = _modules[_modules.length - 1];
                _modules.pop();
                break;
            }
        }

        _moduleBound[_module] = false;
        emit ModuleRemoved(_module);
    }

    /**
     * @inheritdoc IModularCompliance
     */
    function getModules() external view override returns (address[] memory) {
        return _modules;
    }

    /**
     * @inheritdoc IModularCompliance
     */
    function isModuleBound(address _module) external view override returns (bool) {
        return _moduleBound[_module];
    }

    /**
     * @inheritdoc IModularCompliance
     */
    function callModuleFunction(bytes calldata _callData, address _module) external override onlyOwner {
        require(_moduleBound[_module], "ModularCompliance: module not bound");

        // Call the module with the provided data
        (bool success, ) = _module.call(_callData);
        require(success, "ModularCompliance: module call failed");
    }

    // =============================================================
    //                    COMPLIANCE CHECKS
    // =============================================================

    /**
     * @inheritdoc IModularCompliance
     */
    function canTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external view override returns (bool) {
        // Check all modules
        for (uint256 i = 0; i < _modules.length; i++) {
            if (!IComplianceModule(_modules[i]).moduleCheck(_from, _to, _amount, address(this))) {
                return false;
            }
        }
        return true;
    }

    /**
     * @inheritdoc IModularCompliance
     */
    function transferred(
        address _from,
        address _to,
        uint256 _amount
    ) external override onlyToken {
        // Notify all modules
        for (uint256 i = 0; i < _modules.length; i++) {
            IComplianceModule(_modules[i]).moduleTransferAction(_from, _to, _amount, address(this));
        }
    }

    /**
     * @inheritdoc IModularCompliance
     */
    function created(address _to, uint256 _amount) external override onlyToken {
        // Notify all modules
        for (uint256 i = 0; i < _modules.length; i++) {
            IComplianceModule(_modules[i]).moduleMintAction(_to, _amount, address(this));
        }
    }

    /**
     * @inheritdoc IModularCompliance
     */
    function destroyed(address _from, uint256 _amount) external override onlyToken {
        // Notify all modules
        for (uint256 i = 0; i < _modules.length; i++) {
            IComplianceModule(_modules[i]).moduleBurnAction(_from, _amount, address(this));
        }
    }
}
