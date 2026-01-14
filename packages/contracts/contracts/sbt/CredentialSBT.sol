// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IERC5192.sol";

/**
 * @title CredentialSBT
 * @notice EIP-5192 compliant Soul-Bound Token for verified credentials
 * @dev Non-transferable NFTs that represent verified investor credentials
 */
contract CredentialSBT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ReentrancyGuard, IERC5192 {
    // =============================================================
    //                           STORAGE
    // =============================================================

    /// @notice Counter for token IDs
    uint256 private _tokenIdCounter;

    /// @notice Mapping of authorized minters
    mapping(address => bool) public authorizedMinters;

    /// @notice Mapping of token ID to credential type
    mapping(uint256 => uint256) public tokenCredentialType;

    /// @notice Mapping of token ID to credential hash (from ZK proof)
    mapping(uint256 => bytes32) public tokenCredentialHash;

    /// @notice Mapping of token ID to expiration timestamp
    mapping(uint256 => uint256) public tokenExpiration;

    /// @notice Mapping of token ID to issuance timestamp
    mapping(uint256 => uint256) public tokenIssuedAt;

    /// @notice Mapping of address to their SBT tokens by credential type
    mapping(address => mapping(uint256 => uint256)) public userCredentialTokens;

    /// @notice Mapping of credential hash to token ID
    mapping(bytes32 => uint256) public credentialHashToToken;

    /// @notice Base URI for token metadata
    string private _baseTokenURI;

    // =============================================================
    //                         CONSTANTS
    // =============================================================

    /// @notice Credential type for KYC verification
    uint256 public constant CREDENTIAL_TYPE_KYC = 1;

    /// @notice Credential type for accredited investor
    uint256 public constant CREDENTIAL_TYPE_ACCREDITED = 2;

    /// @notice Credential type for qualified purchaser
    uint256 public constant CREDENTIAL_TYPE_QUALIFIED = 3;

    /// @notice Credential type for institutional investor
    uint256 public constant CREDENTIAL_TYPE_INSTITUTIONAL = 4;

    /// @notice Credential type for AML check
    uint256 public constant CREDENTIAL_TYPE_AML = 5;

    // =============================================================
    //                           EVENTS
    // =============================================================

    event CredentialMinted(
        uint256 indexed tokenId,
        address indexed holder,
        uint256 indexed credentialType,
        bytes32 credentialHash,
        uint256 expiration
    );

    event CredentialRevoked(uint256 indexed tokenId, address indexed holder, string reason);
    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);
    event BaseURIUpdated(string newBaseURI);

    // =============================================================
    //                           ERRORS
    // =============================================================

    error SoulboundTokenCannotBeTransferred();
    error NotAuthorizedMinter();
    error CredentialAlreadyExists();
    error InvalidCredentialType();
    error TokenDoesNotExist();
    error InvalidRecipient();

    // =============================================================
    //                          MODIFIERS
    // =============================================================

    modifier onlyMinter() {
        if (!authorizedMinters[msg.sender] && msg.sender != owner()) {
            revert NotAuthorizedMinter();
        }
        _;
    }

    // =============================================================
    //                        CONSTRUCTOR
    // =============================================================

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        _baseTokenURI = baseURI_;
        authorizedMinters[msg.sender] = true;
    }

    // =============================================================
    //                    MINTER MANAGEMENT
    // =============================================================

    /**
     * @notice Adds an authorized minter
     * @param minter The address to authorize
     */
    function addMinter(address minter) external onlyOwner {
        require(minter != address(0), "CredentialSBT: invalid minter");
        authorizedMinters[minter] = true;
        emit MinterAdded(minter);
    }

    /**
     * @notice Removes an authorized minter
     * @param minter The address to remove
     */
    function removeMinter(address minter) external onlyOwner {
        authorizedMinters[minter] = false;
        emit MinterRemoved(minter);
    }

    // =============================================================
    //                     MINTING
    // =============================================================

    /**
     * @notice Mints a credential SBT to a holder
     * @param to The recipient address
     * @param credentialType The type of credential
     * @param credentialHash The hash from the ZK proof
     * @param expiration The expiration timestamp (0 for no expiration)
     * @param tokenURI_ The token URI for metadata
     * @return tokenId The minted token ID
     */
    function mintCredential(
        address to,
        uint256 credentialType,
        bytes32 credentialHash,
        uint256 expiration,
        string calldata tokenURI_
    ) external onlyMinter nonReentrant returns (uint256 tokenId) {
        if (to == address(0)) revert InvalidRecipient();
        if (credentialType == 0) revert InvalidCredentialType();
        if (credentialHashToToken[credentialHash] != 0) revert CredentialAlreadyExists();

        // Check if user already has this credential type
        if (userCredentialTokens[to][credentialType] != 0) {
            // Burn the old token before minting new one
            uint256 oldTokenId = userCredentialTokens[to][credentialType];
            _revokeCredential(oldTokenId, "Replaced with new credential");
        }

        _tokenIdCounter++;
        tokenId = _tokenIdCounter;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI_);

        tokenCredentialType[tokenId] = credentialType;
        tokenCredentialHash[tokenId] = credentialHash;
        tokenExpiration[tokenId] = expiration;
        tokenIssuedAt[tokenId] = block.timestamp;
        userCredentialTokens[to][credentialType] = tokenId;
        credentialHashToToken[credentialHash] = tokenId;

        // Emit Locked event as per EIP-5192
        emit Locked(tokenId);
        emit CredentialMinted(tokenId, to, credentialType, credentialHash, expiration);

        return tokenId;
    }

    /**
     * @notice Batch mints credentials to multiple holders
     * @param recipients Array of recipient addresses
     * @param credentialTypes Array of credential types
     * @param credentialHashes Array of credential hashes
     * @param expirations Array of expiration timestamps
     * @param tokenURIs Array of token URIs
     */
    function batchMintCredentials(
        address[] calldata recipients,
        uint256[] calldata credentialTypes,
        bytes32[] calldata credentialHashes,
        uint256[] calldata expirations,
        string[] calldata tokenURIs
    ) external onlyMinter nonReentrant {
        require(
            recipients.length == credentialTypes.length &&
            credentialTypes.length == credentialHashes.length &&
            credentialHashes.length == expirations.length &&
            expirations.length == tokenURIs.length,
            "CredentialSBT: array length mismatch"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            _mintCredentialInternal(
                recipients[i],
                credentialTypes[i],
                credentialHashes[i],
                expirations[i],
                tokenURIs[i]
            );
        }
    }

    /**
     * @notice Internal mint function
     */
    function _mintCredentialInternal(
        address to,
        uint256 credentialType,
        bytes32 credentialHash,
        uint256 expiration,
        string calldata tokenURI_
    ) internal {
        if (to == address(0)) revert InvalidRecipient();
        if (credentialType == 0) revert InvalidCredentialType();
        if (credentialHashToToken[credentialHash] != 0) revert CredentialAlreadyExists();

        if (userCredentialTokens[to][credentialType] != 0) {
            uint256 oldTokenId = userCredentialTokens[to][credentialType];
            _revokeCredential(oldTokenId, "Replaced with new credential");
        }

        _tokenIdCounter++;
        uint256 tokenId = _tokenIdCounter;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI_);

        tokenCredentialType[tokenId] = credentialType;
        tokenCredentialHash[tokenId] = credentialHash;
        tokenExpiration[tokenId] = expiration;
        tokenIssuedAt[tokenId] = block.timestamp;
        userCredentialTokens[to][credentialType] = tokenId;
        credentialHashToToken[credentialHash] = tokenId;

        emit Locked(tokenId);
        emit CredentialMinted(tokenId, to, credentialType, credentialHash, expiration);
    }

    // =============================================================
    //                     REVOCATION
    // =============================================================

    /**
     * @notice Revokes a credential SBT
     * @param tokenId The token ID to revoke
     * @param reason The reason for revocation
     */
    function revokeCredential(uint256 tokenId, string calldata reason) external onlyMinter {
        _revokeCredential(tokenId, reason);
    }

    /**
     * @notice Internal revocation function
     */
    function _revokeCredential(uint256 tokenId, string memory reason) internal {
        address holder = ownerOf(tokenId);
        uint256 credType = tokenCredentialType[tokenId];
        bytes32 credHash = tokenCredentialHash[tokenId];

        // Clear mappings
        delete userCredentialTokens[holder][credType];
        delete credentialHashToToken[credHash];
        delete tokenCredentialType[tokenId];
        delete tokenCredentialHash[tokenId];
        delete tokenExpiration[tokenId];
        delete tokenIssuedAt[tokenId];

        // Burn the token
        _burn(tokenId);

        emit CredentialRevoked(tokenId, holder, reason);
    }

    // =============================================================
    //                    EIP-5192 IMPLEMENTATION
    // =============================================================

    /**
     * @inheritdoc IERC5192
     * @dev All tokens are always locked (soulbound)
     */
    function locked(uint256 tokenId) external view override returns (bool) {
        // Will revert if token doesn't exist
        ownerOf(tokenId);
        return true; // Always locked
    }

    /**
     * @notice Override _update to prevent transfers
     * @dev Only allows minting (from = 0) and burning (to = 0)
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override(ERC721, ERC721Enumerable) returns (address) {
        address from = _ownerOf(tokenId);

        // Allow minting (from == 0) and burning (to == 0)
        // Prevent regular transfers
        if (from != address(0) && to != address(0)) {
            revert SoulboundTokenCannotBeTransferred();
        }

        return super._update(to, tokenId, auth);
    }

    // =============================================================
    //                    VIEW FUNCTIONS
    // =============================================================

    /**
     * @notice Checks if a holder has a valid credential of a specific type
     * @param holder The address to check
     * @param credentialType The credential type
     * @return valid Whether the credential is valid
     */
    function hasValidCredential(
        address holder,
        uint256 credentialType
    ) external view returns (bool valid) {
        uint256 tokenId = userCredentialTokens[holder][credentialType];
        if (tokenId == 0) {
            return false;
        }

        // Check expiration
        uint256 expiration = tokenExpiration[tokenId];
        if (expiration > 0 && block.timestamp > expiration) {
            return false;
        }

        return true;
    }

    /**
     * @notice Gets all credential token IDs for a holder
     * @param holder The address to query
     * @return tokenIds Array of token IDs
     */
    function getHolderCredentials(address holder) external view returns (uint256[] memory tokenIds) {
        uint256 balance = balanceOf(holder);
        tokenIds = new uint256[](balance);

        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(holder, i);
        }

        return tokenIds;
    }

    /**
     * @notice Gets credential details by token ID
     * @param tokenId The token ID
     * @return holder The token holder
     * @return credentialType The credential type
     * @return credentialHash The credential hash
     * @return issuedAt The issuance timestamp
     * @return expiration The expiration timestamp
     */
    function getCredentialDetails(uint256 tokenId) external view returns (
        address holder,
        uint256 credentialType,
        bytes32 credentialHash,
        uint256 issuedAt,
        uint256 expiration
    ) {
        holder = ownerOf(tokenId);
        credentialType = tokenCredentialType[tokenId];
        credentialHash = tokenCredentialHash[tokenId];
        issuedAt = tokenIssuedAt[tokenId];
        expiration = tokenExpiration[tokenId];
    }

    /**
     * @notice Sets the base URI for token metadata
     * @param baseURI_ The new base URI
     */
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
        emit BaseURIUpdated(baseURI_);
    }

    // =============================================================
    //                    REQUIRED OVERRIDES
    // =============================================================

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return interfaceId == type(IERC5192).interfaceId || super.supportsInterface(interfaceId);
    }
}
