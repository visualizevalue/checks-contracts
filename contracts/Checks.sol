// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./ChecksArt.sol";
import "./ChecksMetadata.sol";
import "./IChecks.sol";
import "./IChecksEdition.sol";
import "./Utilities.sol";

/**
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓ ✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓         ✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓                       ✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓                         ✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓                ✓✓       ✓✓✓✓✓✓✓
✓✓✓✓✓                 ✓✓✓          ✓✓✓✓✓
✓✓✓✓                 ✓✓✓            ✓✓✓✓
✓✓✓✓✓          ✓✓  ✓✓✓             ✓✓✓✓✓
✓✓✓✓✓✓✓✓         ✓✓✓             ✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓                         ✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓                       ✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓          ✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓ ✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
@title  Checks
@author VisualizeValue
@notice This artwork is notable.
*/
contract Checks is IChecks, ERC721 {

    /// @notice The VV Checks Edition contract
    IChecksEdition public editionChecks;

    /// @dev We use this database for persistent storage.
    Checks checks;

    /// @dev Initializes the Checks Originals contract and links the Edition contract.
    constructor() ERC721("Checks", "CHECKS") {
        editionChecks = IChecksEdition(0x34eEBEE6942d8Def3c125458D1a86e0A897fd6f9);
    }

    /// @notice Migrate Checks Editions to Checks Originals by burning the Editions.
    ///         Requires the Approval of this contract on the Edition contract.
    /// @param tokenIds The Edition token IDs you want to migrate.
    function mint(uint256[] calldata tokenIds) external {
        uint32 count = uint32(tokenIds.length);

        // Make sure we have the Editions burn approval from the minter.
        require(editionChecks.isApprovedForAll(msg.sender, address(this)), "Edition burn not approved");

        // Make sure all referenced Editions are owned by or approved to the minter.
        for (uint i = 0; i < count;) {
            uint256 id = tokenIds[i];
            address owner = editionChecks.ownerOf(id);

            require(
                owner == msg.sender ||
                editionChecks.isApprovedForAll(owner, msg.sender) ||
                editionChecks.getApproved(id) == msg.sender,
                "Minter not the owner"
            );

            unchecked { i++; }
        }

        // We need a base seed for pseudo-randomization.
        uint256 randomizer = Utils.seed(checks.minted);

        // Burn the Editions for the given tokenIds & mint the Originals.
        for (uint i = 0; i < count;) {
            uint256 id = tokenIds[i];

            // Burn the edition.
            editionChecks.burn(id);

            // Initialize our Check.
            StoredCheck storage check = checks.all[id];
            check.divisorIndex = 0;

            // Randomized input with a uint32 max value.
            uint256 seed = (randomizer + id) % 4294967296;

            // Check settings.
            check.colorBands[0] = _band(Utils.random(seed + 1, 160));
            check.gradients[0] = _gradient(Utils.random(seed + 2, 100));
            check.animation = uint8(Utils.random(seed + 3, 100));
            check.seed = uint32(seed);

            // Mint the original.
            _mint(msg.sender, id);

            unchecked { i++; }
        }

        // Keep track of how many checks have been minted.
        unchecked { checks.minted += count; }
    }

    /// @notice Get a specific check with its genome settings.
    /// @param tokenId The token ID to fetch.
    function getCheck(uint256 tokenId) external view returns (Check memory check) {
        _requireMinted(tokenId);

        return ChecksArt.getCheck(tokenId, checks);
    }

    /// @notice Sacrifice a token to transfer its visual representation to another token.
    /// @param tokenId The token ID transfer the art into.
    /// @param burnId The token ID to sacrifice.
    function inItForTheArt(uint256 tokenId, uint256 burnId) external {
        _sacrifice(tokenId, burnId);

        unchecked { checks.burned ++; }
    }

    /// @notice Sacrifice multiple tokens to transfer their visual to other tokens.
    /// @param tokenIds The token IDs to transfer the art into.
    /// @param burnIds The token IDs to sacrifice.
    function inItForTheArts(uint256[] calldata tokenIds, uint256[] calldata burnIds) external {
        uint256 pairs = _multiTokenOperation(tokenIds, burnIds);

        for (uint i = 0; i < pairs;) {
            _sacrifice(tokenIds[i], burnIds[i]);

            unchecked { i++; }
        }

        unchecked { checks.burned += uint32(pairs); }
    }

    /// @notice Composite one token into another. This mixes the visual and reduces the number of checks.
    /// @param tokenId The token ID to keep alive. Its visual will change.
    /// @param burnId The token ID to composite into the tokenId.
    function composite(uint256 tokenId, uint256 burnId) external {
        _composite(tokenId, burnId);

        unchecked { checks.burned ++; }
    }

    /// @notice Composite multiple tokens. This mixes the visuals and checks in remaining tokens.
    /// @param tokenIds The token IDs to keep alive. Their art will change.
    /// @param burnIds The token IDs to composite.
    function compositeMany(uint256[] calldata tokenIds, uint256[] calldata burnIds) external {
        uint256 pairs = _multiTokenOperation(tokenIds, burnIds);

        for (uint i = 0; i < pairs;) {
            _composite(tokenIds[i], burnIds[i]);

            unchecked { i++; }
        }

        unchecked { checks.burned += uint32(pairs); }
    }

    /// @notice Sacrifice 64 single-check tokens to form a black check.
    /// @param tokenIds The token IDs to burn for the black check.
    /// @dev The check at index 0 survives.
    function infinity(uint256[] calldata tokenIds) external {
        uint256 count = tokenIds.length;
        require(count == 64, "Final composite requires 64 single Checks");
        for (uint i = 0; i < count;) {
            uint256 id = tokenIds[i];
            require(checks.all[id].divisorIndex == 6, "Non-single Check used");
            require(_isApprovedOrOwner(msg.sender, id), "Not allowed");

            unchecked { i++; }
        }

        // Complete final composite.
        uint256 blackCheckId = tokenIds[0];
        StoredCheck storage check = checks.all[blackCheckId];
        check.divisorIndex = 7;

        // Burn all 63 other Checks.
        for (uint i = 1; i < count;) {
            _burn(tokenIds[i]);

            unchecked { i++; }
        }
        unchecked { checks.burned += 63; }

        // When one is released from the prison of self, that is indeed freedom.
        // For the most great prison is the prison of self.
        emit Infinity(blackCheckId, tokenIds[1:]);
    }

    /// @notice Burn a check. Note: This burn does not composite or swap tokens.
    /// @param tokenId The token ID to burn.
    /// @dev A common purpose burn method.
    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        // Perform the burn.
        _burn(tokenId);

        // Keep track of supply.
        unchecked { checks.burned++; }
    }

    /// @notice Get the colors of all checks in a given token.
    /// @param tokenId The token ID to get colors for.
    /// @dev Consider using the ChecksArt and EightyColors Libraries
    ///      in combination with the getCheck function to resolve this yourself.
    function colors(uint256 tokenId) external view returns (string[] memory, uint256[] memory)
    {
        return ChecksArt.colors(ChecksArt.getCheck(tokenId, checks), checks);
    }

    /// @notice Render the SVG for a given token.
    /// @param tokenId The token to render.
    /// @dev Consider using the ChecksArt Library directly.
    function svg(uint256 tokenId) external view returns (string memory) {
        _requireMinted(tokenId);

        return string(ChecksArt.generateSVG(tokenId, checks));
    }

    /// @notice Get the metadata for a given token.
    /// @param tokenId The token to render.
    /// @dev Consider using the ChecksMetadata Library directly.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        return ChecksMetadata.tokenURI(tokenId, checks);
    }

    /// @notice Returns how many tokens this contract currently manages.
    function totalSupply() public view returns (uint256) {
        return checks.minted - checks.burned;
    }

    /// @dev Sacrifice one token to transfer its art to another.
    /// @param tokenId The token ID to keep.
    /// @param burnId The token ID to burn.
    function _sacrifice(uint256 tokenId, uint256 burnId) internal {
        (
            StoredCheck storage toKeep,
            StoredCheck storage toBurn,
            uint8 divisorIndex
        ) = _tokenOperation(tokenId, burnId);

        // Copy over static genome settings
        toKeep.seed = toBurn.seed;
        toKeep.animation = toBurn.animation;

        // Copy over generational genome settings
        for (uint256 i = 0; i <= divisorIndex;) {
            toKeep.gradients[i] = toBurn.gradients[i];
            toKeep.colorBands[i] = toBurn.colorBands[i];

            unchecked { i++; }
        }

        // Perform the burn.
        _burn(burnId);

        // Notify DAPPs about the Sacrifice.
        emit IChecks.Sacrifice(burnId, tokenId);
    }

    /// @dev Composite one token into to another and burn it.
    /// @param tokenId The token ID to keep. Its art and check-count will change.
    /// @param burnId The token ID to burn in the process.
    function _composite(uint256 tokenId, uint256 burnId) internal {
        (
            StoredCheck storage toKeep,
            StoredCheck storage toBurn,
        ) = _tokenOperation(tokenId, burnId);

        // Composite our check
        uint8 divisorIndex = toKeep.divisorIndex;
        toKeep.composites[divisorIndex] = uint16(burnId);
        toKeep.divisorIndex += 1;

        if (toKeep.divisorIndex < 6) {
            // Need a randomizer for gene manipulation.
            uint256 randomizer = Utils.seed(checks.burned);

            // We take the smallest gradient in 20% of cases, or continue as random checks.
            toKeep.gradients[toKeep.divisorIndex] = Utils.random(randomizer, 100) > 80
                ? Utils.minGt0(toKeep.gradients[divisorIndex], toBurn.gradients[divisorIndex])
                : Utils.min(toKeep.gradients[divisorIndex], toBurn.gradients[divisorIndex]);

            // We breed the lower end average color band when breeding.
            toKeep.colorBands[toKeep.divisorIndex] = Utils.avg(
                toKeep.colorBands[divisorIndex],
                toBurn.colorBands[divisorIndex]
            );

            // Coin-toss keep either one or the other animation setting.
            toKeep.animation = randomizer % 2 == 1 ? toKeep.animation : toBurn.animation;
        }

        // Perform the burn.
        _burn(burnId);

        // Notify DAPPs about the Composite.
        emit IChecks.Composite(tokenId, burnId, ChecksArt.DIVISORS()[toKeep.divisorIndex]);
    }

    /// @dev Make sure this is a valid request to composite/switch with multiple tokens.
    /// @param tokenIds The token IDs to keep.
    /// @param burnIds The token IDs to burn.
    function _multiTokenOperation(uint256[] calldata tokenIds, uint256[] calldata burnIds)
        internal pure returns (uint256 pairs)
    {
        pairs = tokenIds.length;
        require(pairs == burnIds.length, "Invalid number of tokens to composite");
    }

    /// @dev Make sure this is a valid request to composite/switch a token pair.
    /// @param tokenId The token ID to keep.
    /// @param burnId The token ID to burn.
    function _tokenOperation(uint256 tokenId, uint256 burnId)
        internal view returns (
            StoredCheck storage toKeep,
            StoredCheck storage toBurn,
            uint8 divisorIndex
        )
    {
        require(tokenId != burnId, "Same token operation");
        require(
            _isApprovedOrOwner(msg.sender, tokenId) && _isApprovedOrOwner(msg.sender, burnId),
            "Not the owner or approved"
        );

        toKeep = checks.all[tokenId];
        toBurn = checks.all[burnId];
        divisorIndex = toKeep.divisorIndex;

        require(divisorIndex == toBurn.divisorIndex, "Different checks count");
        require(divisorIndex < 6, "Operation on single checks");
    }

    /// @dev Get the index for a token gradient based on a number between 1 and 100.
    /// @param input The pseudorandom input to base the index on.
    function _gradient(uint256 input) internal pure returns(uint8) {
        return input < 80 ? 0
             : input < 96 ? 1
             : uint8(2 + (input % 5));
    }

    /// @dev Get the index for a token color band based on a number between 1 and 160.
    /// @param input The pseudorandom input to base the index on.
    function _band(uint256 input) internal pure returns(uint8) {
        return input > 80 ? 0
             : input > 40 ? 1
             : input > 20 ? 2
             : input > 10 ? 3
             : input >  8 ? 4
             : input >  2 ? 5
             : 6;
    }
}
