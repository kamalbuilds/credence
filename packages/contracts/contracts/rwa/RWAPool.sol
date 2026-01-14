// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./RWAGate.sol";
import "../token/VerifiToken.sol";

/**
 * @title RWAPool
 * @notice Investment pool for Real World Assets
 * @dev Manages deposits, withdrawals, and token distribution with gating
 */
contract RWAPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // =============================================================
    //                           STORAGE
    // =============================================================

    /// @notice The RWA gate contract
    RWAGate public rwaGate;

    /// @notice The RWA security token
    VerifiToken public rwaToken;

    /// @notice The investment asset (e.g., USDC, USDT)
    IERC20 public investmentAsset;

    /// @notice Pool name
    string public poolName;

    /// @notice Pool symbol/identifier
    string public poolSymbol;

    /// @notice Whether the pool is open for investments
    bool public isOpen;

    /// @notice Whether the pool is paused
    bool public isPaused;

    /// @notice Total investment capacity
    uint256 public totalCapacity;

    /// @notice Current total invested
    uint256 public totalInvested;

    /// @notice Exchange rate: tokens per investment unit (scaled by 1e18)
    uint256 public exchangeRate;

    /// @notice Investment deadline (0 for no deadline)
    uint256 public investmentDeadline;

    /// @notice Lock-up period in seconds
    uint256 public lockupPeriod;

    /// @notice Mapping of investor to investment timestamp
    mapping(address => uint256) public investmentTimestamp;

    /// @notice Mapping of investor to invested amount
    mapping(address => uint256) public investedAmount;

    /// @notice Mapping of investor to received tokens
    mapping(address => uint256) public receivedTokens;

    /// @notice Fee percentage (basis points, e.g., 100 = 1%)
    uint256 public feePercentage;

    /// @notice Fee recipient
    address public feeRecipient;

    /// @notice Total fees collected
    uint256 public totalFeesCollected;

    // =============================================================
    //                           EVENTS
    // =============================================================

    event PoolOpened();
    event PoolClosed();
    event PoolPaused();
    event PoolUnpaused();
    event Investment(
        address indexed investor,
        uint256 investmentAmount,
        uint256 tokensReceived,
        uint256 fee
    );
    event Withdrawal(
        address indexed investor,
        uint256 tokensReturned,
        uint256 assetAmount
    );
    event ExchangeRateUpdated(uint256 oldRate, uint256 newRate);
    event CapacityUpdated(uint256 oldCapacity, uint256 newCapacity);
    event FeeUpdated(uint256 oldFee, uint256 newFee);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event EmergencyWithdrawal(address indexed token, address indexed recipient, uint256 amount);

    // =============================================================
    //                           ERRORS
    // =============================================================

    error PoolNotOpen();
    error PoolPausedError();
    error InvestmentDeadlinePassed();
    error CapacityExceeded();
    error InsufficientAllowance();
    error LockupPeriodActive();
    error InsufficientBalance();
    error GateCheckFailed(string reason);
    error ZeroAmount();
    error InvalidConfiguration();

    // =============================================================
    //                          MODIFIERS
    // =============================================================

    modifier whenOpen() {
        if (!isOpen) revert PoolNotOpen();
        _;
    }

    modifier whenNotPaused() {
        if (isPaused) revert PoolPausedError();
        _;
    }

    // =============================================================
    //                        CONSTRUCTOR
    // =============================================================

    /**
     * @notice Constructs the RWAPool
     * @param _rwaGate The RWA gate contract address
     * @param _rwaToken The RWA security token address
     * @param _investmentAsset The investment asset address
     * @param _name Pool name
     * @param _symbol Pool symbol
     * @param _capacity Total investment capacity
     * @param _exchangeRate Initial exchange rate (tokens per asset unit, scaled by 1e18)
     */
    constructor(
        address _rwaGate,
        address _rwaToken,
        address _investmentAsset,
        string memory _name,
        string memory _symbol,
        uint256 _capacity,
        uint256 _exchangeRate
    ) Ownable(msg.sender) {
        require(_rwaGate != address(0), "RWAPool: invalid gate");
        require(_rwaToken != address(0), "RWAPool: invalid token");
        require(_investmentAsset != address(0), "RWAPool: invalid asset");
        require(_exchangeRate > 0, "RWAPool: invalid exchange rate");

        rwaGate = RWAGate(_rwaGate);
        rwaToken = VerifiToken(_rwaToken);
        investmentAsset = IERC20(_investmentAsset);

        poolName = _name;
        poolSymbol = _symbol;
        totalCapacity = _capacity;
        exchangeRate = _exchangeRate;

        feeRecipient = msg.sender;
    }

    // =============================================================
    //                    POOL MANAGEMENT
    // =============================================================

    /**
     * @notice Opens the pool for investments
     */
    function openPool() external onlyOwner {
        isOpen = true;
        emit PoolOpened();
    }

    /**
     * @notice Closes the pool
     */
    function closePool() external onlyOwner {
        isOpen = false;
        emit PoolClosed();
    }

    /**
     * @notice Pauses the pool
     */
    function pause() external onlyOwner {
        isPaused = true;
        emit PoolPaused();
    }

    /**
     * @notice Unpauses the pool
     */
    function unpause() external onlyOwner {
        isPaused = false;
        emit PoolUnpaused();
    }

    /**
     * @notice Sets the investment deadline
     * @param _deadline The deadline timestamp
     */
    function setInvestmentDeadline(uint256 _deadline) external onlyOwner {
        investmentDeadline = _deadline;
    }

    /**
     * @notice Sets the lockup period
     * @param _lockupPeriod The lockup period in seconds
     */
    function setLockupPeriod(uint256 _lockupPeriod) external onlyOwner {
        lockupPeriod = _lockupPeriod;
    }

    /**
     * @notice Updates the exchange rate
     * @param _exchangeRate The new exchange rate
     */
    function setExchangeRate(uint256 _exchangeRate) external onlyOwner {
        if (_exchangeRate == 0) revert InvalidConfiguration();

        uint256 oldRate = exchangeRate;
        exchangeRate = _exchangeRate;

        emit ExchangeRateUpdated(oldRate, _exchangeRate);
    }

    /**
     * @notice Updates the pool capacity
     * @param _capacity The new capacity
     */
    function setCapacity(uint256 _capacity) external onlyOwner {
        uint256 oldCapacity = totalCapacity;
        totalCapacity = _capacity;

        emit CapacityUpdated(oldCapacity, _capacity);
    }

    /**
     * @notice Sets the fee configuration
     * @param _feePercentage Fee percentage in basis points
     * @param _feeRecipient The fee recipient address
     */
    function setFeeConfig(uint256 _feePercentage, address _feeRecipient) external onlyOwner {
        require(_feePercentage <= 1000, "RWAPool: fee too high"); // Max 10%
        require(_feeRecipient != address(0), "RWAPool: invalid recipient");

        uint256 oldFee = feePercentage;
        feePercentage = _feePercentage;
        feeRecipient = _feeRecipient;

        emit FeeUpdated(oldFee, _feePercentage);
    }

    // =============================================================
    //                     INVESTMENT
    // =============================================================

    /**
     * @notice Invests in the pool
     * @param amount The investment amount
     * @return tokensReceived The number of tokens received
     */
    function invest(uint256 amount) external nonReentrant whenOpen whenNotPaused returns (uint256 tokensReceived) {
        if (amount == 0) revert ZeroAmount();
        if (investmentDeadline > 0 && block.timestamp > investmentDeadline) {
            revert InvestmentDeadlinePassed();
        }
        if (totalCapacity > 0 && totalInvested + amount > totalCapacity) {
            revert CapacityExceeded();
        }

        // Check gate
        (bool allowed, string memory reason) = rwaGate.canInvest(msg.sender, address(this), amount);
        if (!allowed) revert GateCheckFailed(reason);

        // Calculate fee
        uint256 fee = (amount * feePercentage) / 10000;
        uint256 netAmount = amount - fee;

        // Calculate tokens to receive
        tokensReceived = (netAmount * exchangeRate) / 1e18;

        // Transfer investment asset
        investmentAsset.safeTransferFrom(msg.sender, address(this), amount);

        // Update state
        totalInvested += amount;
        investedAmount[msg.sender] += netAmount;
        receivedTokens[msg.sender] += tokensReceived;
        investmentTimestamp[msg.sender] = block.timestamp;
        totalFeesCollected += fee;

        // Record in gate
        rwaGate.recordInvestment(msg.sender, address(this), netAmount);

        // Mint RWA tokens to investor
        rwaToken.mint(msg.sender, tokensReceived);

        emit Investment(msg.sender, amount, tokensReceived, fee);

        return tokensReceived;
    }

    /**
     * @notice Calculates the tokens that would be received for an investment
     * @param amount The investment amount
     * @return tokensToReceive The tokens that would be received
     * @return fee The fee that would be charged
     */
    function calculateInvestment(uint256 amount) external view returns (
        uint256 tokensToReceive,
        uint256 fee
    ) {
        fee = (amount * feePercentage) / 10000;
        uint256 netAmount = amount - fee;
        tokensToReceive = (netAmount * exchangeRate) / 1e18;
    }

    // =============================================================
    //                     WITHDRAWAL
    // =============================================================

    /**
     * @notice Withdraws from the pool
     * @param tokenAmount The number of tokens to return
     * @return assetAmount The amount of assets received
     */
    function withdraw(uint256 tokenAmount) external nonReentrant whenNotPaused returns (uint256 assetAmount) {
        if (tokenAmount == 0) revert ZeroAmount();
        if (receivedTokens[msg.sender] < tokenAmount) revert InsufficientBalance();

        // Check lockup
        if (lockupPeriod > 0) {
            if (block.timestamp < investmentTimestamp[msg.sender] + lockupPeriod) {
                revert LockupPeriodActive();
            }
        }

        // Calculate asset amount to return
        assetAmount = (tokenAmount * 1e18) / exchangeRate;

        // Check pool has sufficient assets
        uint256 poolBalance = investmentAsset.balanceOf(address(this)) - totalFeesCollected;
        if (poolBalance < assetAmount) {
            assetAmount = poolBalance;
        }

        // Update state
        receivedTokens[msg.sender] -= tokenAmount;

        // Proportionally reduce invested amount
        uint256 investorTotal = investedAmount[msg.sender];
        uint256 reduction = (investorTotal * tokenAmount) / (receivedTokens[msg.sender] + tokenAmount);
        investedAmount[msg.sender] -= reduction;
        totalInvested -= reduction;

        // Record in gate
        rwaGate.recordWithdrawal(msg.sender, address(this), reduction);

        // Burn tokens from investor
        rwaToken.burn(msg.sender, tokenAmount);

        // Transfer assets
        investmentAsset.safeTransfer(msg.sender, assetAmount);

        emit Withdrawal(msg.sender, tokenAmount, assetAmount);

        return assetAmount;
    }

    // =============================================================
    //                     ADMIN FUNCTIONS
    // =============================================================

    /**
     * @notice Withdraws collected fees
     */
    function withdrawFees() external onlyOwner {
        uint256 fees = totalFeesCollected;
        require(fees > 0, "RWAPool: no fees to withdraw");

        totalFeesCollected = 0;
        investmentAsset.safeTransfer(feeRecipient, fees);

        emit FeesWithdrawn(feeRecipient, fees);
    }

    /**
     * @notice Emergency withdrawal of tokens (owner only)
     * @param token The token to withdraw
     * @param recipient The recipient address
     * @param amount The amount to withdraw
     */
    function emergencyWithdraw(
        address token,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        require(recipient != address(0), "RWAPool: invalid recipient");

        IERC20(token).safeTransfer(recipient, amount);

        emit EmergencyWithdrawal(token, recipient, amount);
    }

    // =============================================================
    //                     VIEW FUNCTIONS
    // =============================================================

    /**
     * @notice Gets the pool information
     * @return name Pool name
     * @return symbol Pool symbol
     * @return capacity Total capacity
     * @return invested Total invested
     * @return rate Exchange rate
     * @return open Whether pool is open
     * @return paused Whether pool is paused
     */
    function getPoolInfo() external view returns (
        string memory name,
        string memory symbol,
        uint256 capacity,
        uint256 invested,
        uint256 rate,
        bool open,
        bool paused
    ) {
        return (
            poolName,
            poolSymbol,
            totalCapacity,
            totalInvested,
            exchangeRate,
            isOpen,
            isPaused
        );
    }

    /**
     * @notice Gets investor information
     * @param investor The investor address
     * @return invested Amount invested
     * @return tokens Tokens received
     * @return timestamp Investment timestamp
     * @return unlockTime When tokens can be withdrawn
     */
    function getInvestorInfo(address investor) external view returns (
        uint256 invested,
        uint256 tokens,
        uint256 timestamp,
        uint256 unlockTime
    ) {
        return (
            investedAmount[investor],
            receivedTokens[investor],
            investmentTimestamp[investor],
            investmentTimestamp[investor] + lockupPeriod
        );
    }

    /**
     * @notice Gets remaining capacity
     * @return remaining The remaining investment capacity
     */
    function getRemainingCapacity() external view returns (uint256) {
        if (totalCapacity == 0) return type(uint256).max;
        if (totalInvested >= totalCapacity) return 0;
        return totalCapacity - totalInvested;
    }
}
