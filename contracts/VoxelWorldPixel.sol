// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title VoxelWorldPixel
 * @notice Voxel World Pixel — 1,111 hand-crafted pixel characters on BNB Chain.
 *
 * Rules (matching voxelworld.fun):
 * - Total supply is capped at 1,111 = 1,000 Free Mint + 111 Genesis Mint.
 * - Free Mint: free, max 4 per wallet, only for Binance Agent ID holders.
 *   Agent ID ownership is verified off-chain; the owner marks verified
 *   wallets with setAgentIdVerified() before they can free-mint.
 *   Free Mint draws randomly from Common & Rare characters only (no Legendary).
 * - Genesis Mint: 0.0015 BNB each, max 5 per wallet, open to all wallets.
 *   Genesis draws randomly from all 12 characters, including Legendary.
 * - Evolve: burn 2 of your own Voxels + 0.001 BNB to receive 1 Evolved Voxel.
 *   The result rises at least 1 rarity tier, except a Legendary result stays
 *   Legendary. Evolved Voxels made only from Free-origin inputs are capped
 *   at Epic — Legendary stays exclusive to Genesis.
 * - All payments stay in this contract. The owner (the deploying wallet)
 *   can withdraw the full balance at any time with withdraw().
 *
 * NOTE on randomness: character draws use a block-based pseudo-random hash.
 * That is fine for a low-price mint, but it is not provably fair. For a
 * high-value launch, switch the draw to Chainlink VRF before opening mint.
 */
contract VoxelWorldPixel is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // ---- Collection constants -------------------------------------------------
    uint256 public constant MAX_SUPPLY = 1111;
    uint256 public constant FREE_SUPPLY = 1000;
    uint256 public constant GENESIS_SUPPLY = 111;
    uint256 public constant GENESIS_PRICE = 0.0015 ether; // in BNB on BNB Chain
    uint256 public constant EVOLVE_PRICE = 0.001 ether; // in BNB on BNB Chain
    uint256 public constant FREE_MAX_PER_WALLET = 4;
    uint256 public constant GENESIS_MAX_PER_WALLET = 5;

    enum Tier {
        Common,
        Rare,
        Epic,
        Legendary
    }
    enum Origin {
        Free,
        Genesis
    }

    struct TokenInfo {
        uint8 characterId; // 1-12
        Tier tier;
        Origin origin;
        bool evolved;
    }

    // ---- State ----------------------------------------------------------------
    uint256 private _nextTokenId = 1;
    uint256 public freeMinted;
    uint256 public genesisMinted;
    bool public mintOpen;
    string private _baseTokenURI;

    mapping(address => bool) public agentIdVerified;
    mapping(address => uint256) public freeMintCount;
    mapping(address => uint256) public genesisMintCount;
    mapping(uint256 => TokenInfo) public tokenInfo;

    /// @dev Free Mint pool: Common & Rare characters only — no Legendary,
    /// and none of the Genesis-tagged characters (#010 Pipi, #012 Mimi are
    /// Rare/Common by tier but excluded here exactly as on the website).
    uint8[7] private _freePool = [1, 2, 3, 5, 6, 8, 9];

    // ---- Events ---------------------------------------------------------------
    event FreeMint(address indexed minter, uint256 indexed tokenId, uint8 characterId);
    event GenesisMint(address indexed minter, uint256 indexed tokenId, uint8 characterId);
    event Evolved(
        address indexed owner,
        uint256 indexed newTokenId,
        uint256 burnedA,
        uint256 burnedB,
        uint8 characterId,
        Tier tier
    );
    event AgentIdVerified(address indexed wallet, bool verified);
    event MintOpenChanged(bool open);
    event Withdrawn(address indexed owner, uint256 amount);

    constructor() ERC721("Voxel World Pixel", "VOXEL") Ownable(msg.sender) {}

    // ---- Character tiers --------------------------------------------------------
    /// @notice Base rarity tier of a character design (Epic is Evolve-only).
    function characterTier(uint8 characterId) public pure returns (Tier) {
        // Legendary: #004 Zuzu, #007 Aurum, #011 Dodo
        if (characterId == 4 || characterId == 7 || characterId == 11) {
            return Tier.Legendary;
        }
        // Rare: #001 Pico, #003 Bibo, #005 Toto, #010 Pipi
        if (
            characterId == 1 || characterId == 3 || characterId == 5 || characterId == 10
        ) {
            return Tier.Rare;
        }
        // Common: #002 Momo, #006 Kiki, #008 Nana, #009 Roro, #012 Mimi
        return Tier.Common;
    }

    // ---- Owner controls ---------------------------------------------------------
    function setMintOpen(bool open_) external onlyOwner {
        mintOpen = open_;
        emit MintOpenChanged(open_);
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        _baseTokenURI = uri;
    }

    /// @notice Mark a wallet as a verified Binance Agent ID holder (or revoke).
    /// Verification of the Agent ID itself happens off-chain by the owner.
    function setAgentIdVerified(address wallet, bool verified) external onlyOwner {
        agentIdVerified[wallet] = verified;
        emit AgentIdVerified(wallet, verified);
    }

    /// @notice Batch version of setAgentIdVerified.
    function setAgentIdVerifiedBatch(address[] calldata wallets, bool verified) external onlyOwner {
        for (uint256 i = 0; i < wallets.length; i++) {
            agentIdVerified[wallets[i]] = verified;
            emit AgentIdVerified(wallets[i], verified);
        }
    }

    /// @notice Withdraw all sale proceeds held by this contract to the owner.
    function withdraw() external onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw");
        (bool ok, ) = payable(owner()).call{value: amount}("");
        require(ok, "Withdraw failed");
        emit Withdrawn(owner(), amount);
    }

    // ---- Random draw --------------------------------------------------------------
    /// @dev Block-based pseudo-random draw. See the note at the top of this file.
    function _drawFromFreePool(uint256 salt) internal view returns (uint8) {
        uint256 rand = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    block.timestamp,
                    msg.sender,
                    salt,
                    freeMinted,
                    genesisMinted
                )
            )
        );
        return _freePool[rand % _freePool.length];
    }

    function _drawFromFullPool(uint256 salt) internal view returns (uint8) {
        uint256 rand = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    block.timestamp,
                    msg.sender,
                    salt,
                    freeMinted,
                    genesisMinted
                )
            )
        );
        return uint8(1 + (rand % 12));
    }

    // ---- Minting --------------------------------------------------------------------
    /// @notice Free Mint — 0 BNB, max 4 per wallet, Binance Agent ID holders only.
    function freeMint(uint256 qty) external nonReentrant {
        require(mintOpen, "Mint is not open yet");
        require(agentIdVerified[msg.sender], "Binance Agent ID not verified");
        require(qty > 0, "Quantity must be at least 1");
        require(freeMintCount[msg.sender] + qty <= FREE_MAX_PER_WALLET, "Free Mint limit reached (max 4)");
        require(freeMinted + qty <= FREE_SUPPLY, "Free Mint sold out");

        for (uint256 i = 0; i < qty; i++) {
            uint8 characterId = _drawFromFreePool(_nextTokenId + i);
            uint256 tokenId = _nextTokenId++;
            freeMinted++;
            freeMintCount[msg.sender]++;
            tokenInfo[tokenId] = TokenInfo({
                characterId: characterId,
                tier: characterTier(characterId),
                origin: Origin.Free,
                evolved: false
            });
            _safeMint(msg.sender, tokenId);
            emit FreeMint(msg.sender, tokenId, characterId);
        }
    }

    /// @notice Genesis Mint — 0.0015 BNB each, max 5 per wallet, full pool incl. Legendary.
    function genesisMint(uint256 qty) external payable nonReentrant {
        require(mintOpen, "Mint is not open yet");
        require(qty > 0, "Quantity must be at least 1");
        require(genesisMintCount[msg.sender] + qty <= GENESIS_MAX_PER_WALLET, "Genesis limit reached (max 5)");
        require(genesisMinted + qty <= GENESIS_SUPPLY, "Genesis sold out");
        require(msg.value == GENESIS_PRICE * qty, "Send exactly 0.0015 BNB per Genesis Voxel");

        for (uint256 i = 0; i < qty; i++) {
            uint8 characterId = _drawFromFullPool(_nextTokenId + i);
            uint256 tokenId = _nextTokenId++;
            genesisMinted++;
            genesisMintCount[msg.sender]++;
            tokenInfo[tokenId] = TokenInfo({
                characterId: characterId,
                tier: characterTier(characterId),
                origin: Origin.Genesis,
                evolved: false
            });
            _safeMint(msg.sender, tokenId);
            emit GenesisMint(msg.sender, tokenId, characterId);
        }
    }

    // ---- Evolve ---------------------------------------------------------------------
    /// @notice Burn 2 of your Voxels + 0.001 BNB to receive 1 Evolved Voxel.
    function evolve(uint256 tokenA, uint256 tokenB) external payable nonReentrant {
        require(msg.value == EVOLVE_PRICE, "Send exactly 0.001 BNB to evolve");
        require(tokenA != tokenB, "Pick two different Voxels");
        require(ownerOf(tokenA) == msg.sender, "You do not own the first Voxel");
        require(ownerOf(tokenB) == msg.sender, "You do not own the second Voxel");

        TokenInfo memory a = tokenInfo[tokenA];
        TokenInfo memory b = tokenInfo[tokenB];

        // Result tier: at least +1 above the higher input tier.
        Tier higher = a.tier >= b.tier ? a.tier : b.tier;
        Tier result = higher == Tier.Legendary ? Tier.Legendary : Tier(uint256(higher) + 1);
        // Evolved from Free-origin inputs only: capped at Epic.
        bool genesisOrigin = a.origin == Origin.Genesis || b.origin == Origin.Genesis;
        if (!genesisOrigin && result > Tier.Epic) {
            result = Tier.Epic;
        }
        // The Evolved Voxel keeps the character of the higher-tier input.
        uint8 characterId = a.tier >= b.tier ? a.characterId : b.characterId;

        _burn(tokenA);
        _burn(tokenB);
        delete tokenInfo[tokenA];
        delete tokenInfo[tokenB];

        uint256 tokenId = _nextTokenId++;
        tokenInfo[tokenId] = TokenInfo({
            characterId: characterId,
            tier: result,
            origin: genesisOrigin ? Origin.Genesis : Origin.Free,
            evolved: true
        });
        _safeMint(msg.sender, tokenId);
        emit Evolved(msg.sender, tokenId, tokenA, tokenB, characterId, result);
    }

    // ---- Views ------------------------------------------------------------------------
    /// @notice Total Voxels ever minted through Free + Genesis (cap 1,111).
    /// Evolve outputs are not counted here: evolving burns 2 and mints 1,
    /// so circulating supply only shrinks.
    function totalMinted() external view returns (uint256) {
        return freeMinted + genesisMinted;
    }

    function getTokenInfo(uint256 tokenId) external view returns (TokenInfo memory) {
        _requireOwned(tokenId);
        return tokenInfo[tokenId];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        TokenInfo memory info = tokenInfo[tokenId];
        string memory file = info.evolved
            ? string(abi.encodePacked("evolved-", uint256(info.characterId).toString(), ".json"))
            : string(abi.encodePacked(uint256(info.characterId).toString(), ".json"));
        return string(abi.encodePacked(_baseTokenURI, file));
    }
}
