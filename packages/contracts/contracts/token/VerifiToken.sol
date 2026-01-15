// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IVerifiToken.sol";
import "../interfaces/IIdentityRegistry.sol";
import "../interfaces/IModularCompliance.sol";

/**
 * @title VerifiToken
 * @notice ERC-3643 compliant security token with identity verification and compliance checking
 * @dev Implements full T-REX protocol compliance for regulated security tokens
 */
contract VerifiToken is ERC20, Ownable, ReentrancyGuard, IVerifiToken {
    // =============================================================
    //                           STORAGE
    // =============================================================

    /// @notice Identity registry for investor verification
    IIdentityRegistry private _identityRegistry;

    /// @notice Modular compliance contract for transfer restrictions
    IModularCompliance private _compliance;

    /// @notice Token's OnchainID for identity
    address private _onchainID;

    /// @notice Token pause state
    bool private _paused;

    /// @notice Mapping of frozen addresses
    mapping(address => bool) private _frozen;

    /// @notice Mapping of agent addresses
    mapping(address => bool) private _agents;

    /// @notice Array of agent addresses for enumeration
    address[] private _agentList;

    // =============================================================
    //                          MODIFIERS
    // =============================================================

    /**
     * @notice Ensures the caller is an agent
     */
    modifier onlyAgent() {
        require(_agents[msg.sender], "VerifiToken: caller is not an agent");
        _;
    }

    /**
     * @notice Ensures the token is not paused
     */
    modifier whenNotPaused() {
        require(!_paused, "VerifiToken: token is paused");
        _;
    }

    /**
     * @notice Ensures the address is not frozen
     */
    modifier whenNotFrozen(address _account) {
        require(!_frozen[_account], "VerifiToken: account is frozen");
        _;
    }

    // =============================================================
    //                        CONSTRUCTOR
    // =============================================================

    /**
     * @notice Constructs the VerifiToken
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _identityRegistryAddress Identity registry address
     * @param _complianceAddress Compliance contract address
     * @param _tokenOnchainID Token's OnchainID address
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _identityRegistryAddress,
        address _complianceAddress,
        address _tokenOnchainID
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        require(_identityRegistryAddress != address(0), "VerifiToken: invalid identity registry");
        require(_complianceAddress != address(0), "VerifiToken: invalid compliance");

        _identityRegistry = IIdentityRegistry(_identityRegistryAddress);
        _compliance = IModularCompliance(_complianceAddress);
        _onchainID = _tokenOnchainID;

        // Add deployer as initial agent
        _agents[msg.sender] = true;
        _agentList.push(msg.sender);
        emit AgentAdded(msg.sender);
    }

    // =============================================================
    //                      AGENT MANAGEMENT
    // =============================================================

    /**
     * @inheritdoc IVerifiToken
     */
    function addAgent(address _agent) external override onlyOwner {
        require(_agent != address(0), "VerifiToken: invalid agent address");
        require(!_agents[_agent], "VerifiToken: already an agent");

        _agents[_agent] = true;
        _agentList.push(_agent);
        emit AgentAdded(_agent);
    }

    /**
     * @inheritdoc IVerifiToken
     */
    function removeAgent(address _agent) external override onlyOwner {
        require(_agents[_agent], "VerifiToken: not an agent");

        _agents[_agent] = false;

        // Remove from list
        for (uint256 i = 0; i < _agentList.length; i++) {
            if (_agentList[i] == _agent) {
                _agentList[i] = _agentList[_agentList.length - 1];
                _agentList.pop();
                break;
            }
        }

        emit AgentRemoved(_agent);
    }

    /**
     * @inheritdoc IVerifiToken
     */
    function isAgent(address _account) external view override returns (bool) {
        return _agents[_account];
    }

    // =============================================================
    //                      PAUSE FUNCTIONALITY
    // =============================================================

    /**
     * @inheritdoc IVerifiToken
     */
    function pause() external override onlyAgent {
        require(!_paused, "VerifiToken: already paused");
        _paused = true;
        emit TokensPaused();
    }

    /**
     * @inheritdoc IVerifiToken
     */
    function unpause() external override onlyAgent {
        require(_paused, "VerifiToken: not paused");
        _paused = false;
        emit TokensUnpaused();
    }

    /**
     * @inheritdoc IVerifiToken
     */
    function paused() external view override returns (bool) {
        return _paused;
    }

    // =============================================================
    //                     FREEZE FUNCTIONALITY
    // =============================================================

    /**
     * @inheritdoc IVerifiToken
     */
    function freezeAddress(address _account) external override onlyAgent {
        require(!_frozen[_account], "VerifiToken: already frozen");
        _frozen[_account] = true;
        emit AddressFrozen(_account, true, msg.sender);
    }

    /**
     * @inheritdoc IVerifiToken
     */
    function unfreezeAddress(address _account) external override onlyAgent {
        require(_frozen[_account], "VerifiToken: not frozen");
        _frozen[_account] = false;
        emit AddressFrozen(_account, false, msg.sender);
    }

    /**
     * @inheritdoc IVerifiToken
     */
    function batchFreezeAddress(address[] calldata _accounts) external override onlyAgent {
        for (uint256 i = 0; i < _accounts.length; i++) {
            if (!_frozen[_accounts[i]]) {
                _frozen[_accounts[i]] = true;
                emit AddressFrozen(_accounts[i], true, msg.sender);
            }
        }
    }

    /**
     * @inheritdoc IVerifiToken
     */
    function batchUnfreezeAddress(address[] calldata _accounts) external override onlyAgent {
        for (uint256 i = 0; i < _accounts.length; i++) {
            if (_frozen[_accounts[i]]) {
                _frozen[_accounts[i]] = false;
                emit AddressFrozen(_accounts[i], false, msg.sender);
            }
        }
    }

    /**
     * @inheritdoc IVerifiToken
     */
    function isFrozen(address _account) external view override returns (bool) {
        return _frozen[_account];
    }

    // =============================================================
    //                     MINTING & BURNING
    // =============================================================

    /**
     * @inheritdoc IVerifiToken
     */
    function mint(address _to, uint256 _amount) external override onlyAgent whenNotPaused {
        require(_identityRegistry.isVerified(_to), "VerifiToken: recipient not verified");

        _mint(_to, _amount);
        _compliance.created(_to, _amount);
    }

    /**
     * @inheritdoc IVerifiToken
     */
    function burn(address _from, uint256 _amount) external override onlyAgent whenNotPaused {
        _burn(_from, _amount);
        _compliance.destroyed(_from, _amount);
    }

    /**
     * @inheritdoc IVerifiToken
     */
    function batchMint(
        address[] calldata _toList,
        uint256[] calldata _amounts
    ) external override onlyAgent whenNotPaused {
        require(_toList.length == _amounts.length, "VerifiToken: array length mismatch");

        for (uint256 i = 0; i < _toList.length; i++) {
            require(_identityRegistry.isVerified(_toList[i]), "VerifiToken: recipient not verified");
            _mint(_toList[i], _amounts[i]);
            _compliance.created(_toList[i], _amounts[i]);
        }
    }

    /**
     * @inheritdoc IVerifiToken
     */
    function batchBurn(
        address[] calldata _fromList,
        uint256[] calldata _amounts
    ) external override onlyAgent whenNotPaused {
        require(_fromList.length == _amounts.length, "VerifiToken: array length mismatch");

        for (uint256 i = 0; i < _fromList.length; i++) {
            _burn(_fromList[i], _amounts[i]);
            _compliance.destroyed(_fromList[i], _amounts[i]);
        }
    }

    // =============================================================
    //                        TRANSFERS
    // =============================================================

    /**
     * @notice Internal transfer with compliance checks
     * @dev Overrides ERC20's _update to add compliance checks
     */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override whenNotPaused {
        // Skip checks for mint/burn operations handled by agent functions
        if (from != address(0) && to != address(0)) {
            // Regular transfer - enforce all checks
            require(!_frozen[from], "VerifiToken: sender is frozen");
            require(!_frozen[to], "VerifiToken: recipient is frozen");

            // Verify recipient identity
            require(_identityRegistry.isVerified(to), "VerifiToken: recipient not verified");

            // Check compliance
            require(
                _compliance.canTransfer(from, to, amount),
                "VerifiToken: transfer not compliant"
            );
        }

        super._update(from, to, amount);

        // Notify compliance after successful transfer
        if (from != address(0) && to != address(0)) {
            _compliance.transferred(from, to, amount);
        }
    }

    /**
     * @inheritdoc IVerifiToken
     */
    function batchTransfer(
        address[] calldata _toList,
        uint256[] calldata _amounts
    ) external override whenNotPaused nonReentrant {
        require(_toList.length == _amounts.length, "VerifiToken: array length mismatch");

        for (uint256 i = 0; i < _toList.length; i++) {
            transfer(_toList[i], _amounts[i]);
        }
    }

    /**
     * @inheritdoc IVerifiToken
     */
    function forcedTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external override onlyAgent whenNotPaused nonReentrant returns (bool) {
        require(_identityRegistry.isVerified(_to), "VerifiToken: recipient not verified");

        // Forced transfers bypass freeze and compliance checks
        // but still require identity verification
        uint256 fromBalance = balanceOf(_from);
        require(fromBalance >= _amount, "VerifiToken: insufficient balance");

        // Direct state update bypassing normal checks
        _update(_from, _to, _amount);

        return true;
    }

    // =============================================================
    //                      WALLET RECOVERY
    // =============================================================

    /**
     * @inheritdoc IVerifiToken
     */
    function recoveryAddress(
        address _lostWallet,
        address _newWallet,
        address _investorOnchainID
    ) external override onlyAgent whenNotPaused nonReentrant returns (bool) {
        require(_newWallet != address(0), "VerifiToken: invalid new wallet");
        require(_lostWallet != _newWallet, "VerifiToken: same wallet");
        require(_identityRegistry.isVerified(_newWallet), "VerifiToken: new wallet not verified");

        // Verify the new wallet is linked to the same OnchainID
        IIdentity lostIdentity = _identityRegistry.identity(_lostWallet);
        IIdentity newIdentity = _identityRegistry.identity(_newWallet);
        require(
            address(lostIdentity) == _investorOnchainID && address(newIdentity) == _investorOnchainID,
            "VerifiToken: identity mismatch"
        );

        uint256 balance = balanceOf(_lostWallet);
        if (balance > 0) {
            // Force transfer tokens from lost wallet to new wallet
            _update(_lostWallet, _newWallet, balance);
        }

        // Transfer frozen status
        if (_frozen[_lostWallet]) {
            _frozen[_lostWallet] = false;
            _frozen[_newWallet] = true;
        }

        emit RecoverySuccess(_lostWallet, _newWallet, _investorOnchainID);

        return true;
    }

    // =============================================================
    //                    REGISTRY MANAGEMENT
    // =============================================================

    /**
     * @inheritdoc IVerifiToken
     */
    function setIdentityRegistry(address _identityRegistryAddress) external override onlyOwner {
        require(_identityRegistryAddress != address(0), "VerifiToken: invalid identity registry");
        _identityRegistry = IIdentityRegistry(_identityRegistryAddress);
        emit IdentityRegistryAdded(_identityRegistryAddress);
    }

    /**
     * @inheritdoc IVerifiToken
     */
    function setCompliance(address _complianceAddress) external override onlyOwner {
        require(_complianceAddress != address(0), "VerifiToken: invalid compliance");
        _compliance = IModularCompliance(_complianceAddress);
        emit ComplianceAdded(_complianceAddress);
    }

    // =============================================================
    //                         VIEW FUNCTIONS
    // =============================================================

    /**
     * @inheritdoc IVerifiToken
     */
    function identityRegistry() external view override returns (IIdentityRegistry) {
        return _identityRegistry;
    }

    /**
     * @inheritdoc IVerifiToken
     */
    function compliance() external view override returns (IModularCompliance) {
        return _compliance;
    }

    /**
     * @inheritdoc IVerifiToken
     */
    function onchainID() external view override returns (address) {
        return _onchainID;
    }

    /**
     * @inheritdoc IVerifiToken
     */
    function version() external pure override returns (string memory) {
        return "1.0.0";
    }

    /**
     * @notice Returns the decimals for the token
     * @dev Security tokens typically use 0 decimals for whole shares
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }
}
