// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IIdentityRegistry.sol";
import "../sbt/CredentialSBT.sol";
import "../verifier/SP1CredentialVerifier.sol";

/**
 * @title RWAGate
 * @notice Gatekeeper contract for RWA investments
 * @dev Controls access to RWA pools based on verified credentials
 */
contract RWAGate is Ownable, ReentrancyGuard {
    // =============================================================
    //                           STORAGE
    // =============================================================

    /// @notice Identity registry for investor verification
    IIdentityRegistry public identityRegistry;

    /// @notice Credential SBT contract
    CredentialSBT public credentialSBT;

    /// @notice SP1 credential verifier
    SP1CredentialVerifier public credentialVerifier;

    /// @notice Mapping of whitelisted pools
    mapping(address => bool) public whitelistedPools;

    /// @notice Mapping of pool-specific required credential types
    mapping(address => uint256[]) public poolRequiredCredentials;

    /// @notice Mapping of pool-specific minimum investment amounts
    mapping(address => uint256) public poolMinInvestment;

    /// @notice Mapping of pool-specific maximum investment amounts
    mapping(address => uint256) public poolMaxInvestment;

    /// @notice Mapping of investor to pool to invested amount
    mapping(address => mapping(address => uint256)) public investorPoolAmount;

    /// @notice Global investor whitelist override
    mapping(address => bool) public globalWhitelist;

    /// @notice Whether to require identity registry verification
    bool public requireIdentityVerification;

    /// @notice Whether to require SBT credentials
    bool public requireSBTCredentials;

    // =============================================================
    //                           EVENTS
    // =============================================================

    event PoolWhitelisted(address indexed pool);
    event PoolRemoved(address indexed pool);
    event PoolConfigured(
        address indexed pool,
        uint256[] requiredCredentials,
        uint256 minInvestment,
        uint256 maxInvestment
    );
    event InvestorApproved(address indexed investor, address indexed pool);
    event InvestorInvested(address indexed investor, address indexed pool, uint256 amount);
    event InvestorWithdrew(address indexed investor, address indexed pool, uint256 amount);
    event GlobalWhitelistUpdated(address indexed investor, bool status);
    event IdentityVerificationToggled(bool required);
    event SBTCredentialsToggled(bool required);

    // =============================================================
    //                           ERRORS
    // =============================================================

    error PoolNotWhitelisted();
    error InvestorNotVerified();
    error MissingRequiredCredential();
    error InvestmentBelowMinimum();
    error InvestmentAboveMaximum();
    error InvalidPool();
    error ZeroAddress();

    // =============================================================
    //                        CONSTRUCTOR
    // =============================================================

    /**
     * @notice Constructs the RWAGate
     * @param _identityRegistry The identity registry address
     * @param _credentialSBT The credential SBT contract address
     * @param _credentialVerifier The SP1 credential verifier address
     */
    constructor(
        address _identityRegistry,
        address _credentialSBT,
        address _credentialVerifier
    ) Ownable(msg.sender) {
        if (_identityRegistry != address(0)) {
            identityRegistry = IIdentityRegistry(_identityRegistry);
        }
        if (_credentialSBT != address(0)) {
            credentialSBT = CredentialSBT(_credentialSBT);
        }
        if (_credentialVerifier != address(0)) {
            credentialVerifier = SP1CredentialVerifier(_credentialVerifier);
        }

        requireIdentityVerification = true;
        requireSBTCredentials = true;
    }

    // =============================================================
    //                    CONFIGURATION
    // =============================================================

    /**
     * @notice Sets the identity registry
     * @param _identityRegistry The new identity registry address
     */
    function setIdentityRegistry(address _identityRegistry) external onlyOwner {
        if (_identityRegistry == address(0)) revert ZeroAddress();
        identityRegistry = IIdentityRegistry(_identityRegistry);
    }

    /**
     * @notice Sets the credential SBT contract
     * @param _credentialSBT The new credential SBT address
     */
    function setCredentialSBT(address _credentialSBT) external onlyOwner {
        if (_credentialSBT == address(0)) revert ZeroAddress();
        credentialSBT = CredentialSBT(_credentialSBT);
    }

    /**
     * @notice Sets the credential verifier
     * @param _credentialVerifier The new credential verifier address
     */
    function setCredentialVerifier(address _credentialVerifier) external onlyOwner {
        if (_credentialVerifier == address(0)) revert ZeroAddress();
        credentialVerifier = SP1CredentialVerifier(_credentialVerifier);
    }

    /**
     * @notice Toggles identity verification requirement
     * @param _required Whether identity verification is required
     */
    function setRequireIdentityVerification(bool _required) external onlyOwner {
        requireIdentityVerification = _required;
        emit IdentityVerificationToggled(_required);
    }

    /**
     * @notice Toggles SBT credential requirement
     * @param _required Whether SBT credentials are required
     */
    function setRequireSBTCredentials(bool _required) external onlyOwner {
        requireSBTCredentials = _required;
        emit SBTCredentialsToggled(_required);
    }

    // =============================================================
    //                    POOL MANAGEMENT
    // =============================================================

    /**
     * @notice Whitelists a pool
     * @param pool The pool address
     */
    function whitelistPool(address pool) external onlyOwner {
        if (pool == address(0)) revert InvalidPool();
        whitelistedPools[pool] = true;
        emit PoolWhitelisted(pool);
    }

    /**
     * @notice Removes a pool from whitelist
     * @param pool The pool address
     */
    function removePool(address pool) external onlyOwner {
        whitelistedPools[pool] = false;
        emit PoolRemoved(pool);
    }

    /**
     * @notice Configures pool requirements
     * @param pool The pool address
     * @param requiredCredentials Array of required credential types
     * @param minInvestment Minimum investment amount
     * @param maxInvestment Maximum investment amount (0 for unlimited)
     */
    function configurePool(
        address pool,
        uint256[] calldata requiredCredentials,
        uint256 minInvestment,
        uint256 maxInvestment
    ) external onlyOwner {
        if (!whitelistedPools[pool]) revert PoolNotWhitelisted();

        poolRequiredCredentials[pool] = requiredCredentials;
        poolMinInvestment[pool] = minInvestment;
        poolMaxInvestment[pool] = maxInvestment;

        emit PoolConfigured(pool, requiredCredentials, minInvestment, maxInvestment);
    }

    /**
     * @notice Updates global whitelist status for an investor
     * @param investor The investor address
     * @param status The whitelist status
     */
    function setGlobalWhitelist(address investor, bool status) external onlyOwner {
        globalWhitelist[investor] = status;
        emit GlobalWhitelistUpdated(investor, status);
    }

    /**
     * @notice Batch updates global whitelist
     * @param investors Array of investor addresses
     * @param status The whitelist status
     */
    function batchSetGlobalWhitelist(address[] calldata investors, bool status) external onlyOwner {
        for (uint256 i = 0; i < investors.length; i++) {
            globalWhitelist[investors[i]] = status;
            emit GlobalWhitelistUpdated(investors[i], status);
        }
    }

    // =============================================================
    //                    GATING LOGIC
    // =============================================================

    /**
     * @notice Checks if an investor can invest in a pool
     * @param investor The investor address
     * @param pool The pool address
     * @param amount The investment amount
     * @return allowed Whether the investment is allowed
     * @return reason Reason if not allowed
     */
    function canInvest(
        address investor,
        address pool,
        uint256 amount
    ) external view returns (bool allowed, string memory reason) {
        // Check if pool is whitelisted
        if (!whitelistedPools[pool]) {
            return (false, "Pool not whitelisted");
        }

        // Check global whitelist override
        if (globalWhitelist[investor]) {
            return (true, "");
        }

        // Check identity verification
        if (requireIdentityVerification && address(identityRegistry) != address(0)) {
            if (!identityRegistry.isVerified(investor)) {
                return (false, "Investor not verified in identity registry");
            }
        }

        // Check SBT credentials
        if (requireSBTCredentials && address(credentialSBT) != address(0)) {
            uint256[] memory requiredCreds = poolRequiredCredentials[pool];
            for (uint256 i = 0; i < requiredCreds.length; i++) {
                if (!credentialSBT.hasValidCredential(investor, requiredCreds[i])) {
                    return (false, "Missing required credential");
                }
            }
        }

        // Check investment limits
        uint256 currentInvestment = investorPoolAmount[investor][pool];
        uint256 totalAfterInvestment = currentInvestment + amount;

        if (poolMinInvestment[pool] > 0 && totalAfterInvestment < poolMinInvestment[pool]) {
            return (false, "Investment below minimum");
        }

        if (poolMaxInvestment[pool] > 0 && totalAfterInvestment > poolMaxInvestment[pool]) {
            return (false, "Investment above maximum");
        }

        return (true, "");
    }

    /**
     * @notice Records an investment (called by pool contracts)
     * @param investor The investor address
     * @param pool The pool address
     * @param amount The investment amount
     */
    function recordInvestment(
        address investor,
        address pool,
        uint256 amount
    ) external nonReentrant {
        require(msg.sender == pool, "RWAGate: caller is not the pool");
        require(whitelistedPools[pool], "RWAGate: pool not whitelisted");

        investorPoolAmount[investor][pool] += amount;
        emit InvestorInvested(investor, pool, amount);
    }

    /**
     * @notice Records a withdrawal (called by pool contracts)
     * @param investor The investor address
     * @param pool The pool address
     * @param amount The withdrawal amount
     */
    function recordWithdrawal(
        address investor,
        address pool,
        uint256 amount
    ) external nonReentrant {
        require(msg.sender == pool, "RWAGate: caller is not the pool");
        require(investorPoolAmount[investor][pool] >= amount, "RWAGate: insufficient investment");

        investorPoolAmount[investor][pool] -= amount;
        emit InvestorWithdrew(investor, pool, amount);
    }

    // =============================================================
    //                    VIEW FUNCTIONS
    // =============================================================

    /**
     * @notice Gets the pool configuration
     * @param pool The pool address
     * @return requiredCredentials Array of required credential types
     * @return minInvestment Minimum investment
     * @return maxInvestment Maximum investment
     */
    function getPoolConfig(address pool) external view returns (
        uint256[] memory requiredCredentials,
        uint256 minInvestment,
        uint256 maxInvestment
    ) {
        return (
            poolRequiredCredentials[pool],
            poolMinInvestment[pool],
            poolMaxInvestment[pool]
        );
    }

    /**
     * @notice Gets an investor's investment in a pool
     * @param investor The investor address
     * @param pool The pool address
     * @return amount The invested amount
     */
    function getInvestment(address investor, address pool) external view returns (uint256) {
        return investorPoolAmount[investor][pool];
    }
}
