// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./IChecksEdition.sol";
import "./IChecks.sol";
import "./ChecksArt.sol";
import "./ChecksMetadata.sol";
import "./Utilities.sol";

import "hardhat/console.sol";


//✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓            ✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓                  ✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓        ✓                ✓        ✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓                                        ✓✓✓✓✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓✓✓✓                                          ✓✓✓✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓✓✓✓                                          ✓✓✓✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓✓✓✓                            ✓✓✓           ✓✓✓✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓    ✓                        ✓✓✓✓✓         ✓    ✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓                            ✓✓✓✓✓                 ✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓                           ✓✓✓✓✓                    ✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓               ✓✓✓       ✓✓✓✓✓                      ✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓               ✓✓✓✓✓   ✓✓✓✓✓                       ✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓                ✓✓✓✓✓✓✓✓✓                        ✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓✓ ✓              ✓✓✓✓✓                      ✓ ✓✓✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓✓✓✓                                          ✓✓✓✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓✓✓✓                                          ✓✓✓✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓                                        ✓✓✓✓✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓                                     ✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓      ✓                ✓      ✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓                 ✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓           ✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
//✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
contract Checks is IChecks, ERC721 {
    IChecksEdition public editionChecks;

    // Our DB
    Checks checks;

    constructor() ERC721("Checks", "Check") {
        // Link Checks to the Edition Contract
        editionChecks = IChecksEdition(0x34eEBEE6942d8Def3c125458D1a86e0A897fd6f9);
    }

    function mint(uint256[] calldata tokenIds) public {
        uint32 count = uint32(tokenIds.length);

        // Make sure we have the Editions burn approval from the minter.
        require(editionChecks.isApprovedForAll(msg.sender, address(this)), "Edition burn not approved");

        // Make sure all referenced Editions are owned by or approved to the minter.
        for (uint i = 0; i < count;) {
            require(editionChecks.ownerOf(tokenIds[i]) == msg.sender, "Minter not the owner");

            unchecked { i++; }
        }

        // We need a base seed for pseudo-randomization
        uint256 randomizer = Utils.seed(checks.minted);

        // Burn the Editions for the given tokenIds & mint the Originals.
        for (uint i = 0; i < count;) {
            uint256 id = tokenIds[i];

            // Burn the edition
            editionChecks.burn(id);

            // Initialize Check
            StoredCheck storage check = checks.all[id];
            check.divisorIndex = 0;

            // Randomized input
            uint256 seed = randomizer + id;
            // uint256 gradientInput = uint8(Utils.random(seed + 1, 0, 100));
            // uint256 speedInput = uint8(Utils.random(seed + 2, 0, 100));
            // uint256 bandInput = uint8(Utils.random(seed + 3, 1, 160));

            // Check settings

            check.gradients[0] = _gradient(Utils.random(seed + 1, 1, 100));
            check.colorBands[0] = _band(Utils.random(seed + 2, 1, 160));
            // check.speed = uint8(Utils.random(seed + 3, 1, 100));
            check.speed = 2;
            check.seed = uint32(seed % 4294967296); // max is the highest uint32

            // check.gradients[0] = gradientInput < 80 ? 0
            //                   : gradientInput < 96 ? 1
            //                   : [2, 5, 8, 9, 10]
            //                     [seed % 5];

            // check.colorBands[0] = bandInput > 80 ? 80
            //                    : bandInput > 40 ? 40
            //                    : bandInput > 20 ? 20
            //                    : bandInput > 10 ? 10
            //                    : bandInput > 8 ? 5
            //                    : bandInput > 2 ? 4
            //                    : 1;

            // check.speed = speedInput < 20 ? 4
            //             : speedInput < 80 ? 2
            //             : 1;

            _mint(msg.sender, id);

            unchecked { i++; }
        }

        // Keep track of how many checks have been minted
        unchecked { checks.minted += count; }
    }

    function _gradient(uint256 input) internal pure returns(uint8) {
        return input < 80 ? 0
             : input < 96 ? 1
             : [2, 5, 8, 9, 10][input % 5];
    }

    function _band(uint256 input) internal pure returns(uint8) {
        return input > 80 ? 80
             : input > 40 ? 40
             : input > 20 ? 20
             : input > 10 ? 10
             : input >  8 ? 5
             : input >  2 ? 4
             : 1;
    }

    function getCheck(uint256 tokenId) public view returns (Check memory check) {
        _requireMinted(tokenId);

        return ChecksArt.getCheck(tokenId, checks);
    }

    function inItForTheArt(uint256 tokenId, uint256 burnId) public {
        _sacrifice(tokenId, burnId);

        unchecked { checks.burned ++; }
    }

    function inItForTheArts(uint256[] calldata tokenIds, uint256[] calldata burnIds) public {
        uint256 pairs =_multiTokenOperation(tokenIds, burnIds);

        for (uint i = 0; i < pairs;) {
            _sacrifice(tokenIds[i], burnIds[i]);

            unchecked { i++; }
        }

        unchecked { checks.burned += uint32(pairs); }
    }

    function composite(uint256 tokenId, uint256 burnId) public {
        _composite(tokenId, burnId);

        unchecked { checks.burned ++; }
    }

    function compositeMany(uint256[] calldata tokenIds, uint256[] calldata burnIds) public {
        uint256 pairs =_multiTokenOperation(tokenIds, burnIds);

        for (uint i = 0; i < pairs;) {
            _composite(tokenIds[i], burnIds[i]);

            unchecked { i++; }
        }

        unchecked { checks.burned += uint32(pairs); }
    }

    function infinity(uint256[] calldata tokenIds) public {
        uint256 count = tokenIds.length;
        require(count == 64, "Final composite requires 64 single Checks");
        for (uint i = 0; i < count;) {
            require(checks.all[tokenIds[i]].divisorIndex == 6, "Non-single Check used");

            unchecked { i++; }
        }

        // Complete final composite.
        uint256 id = tokenIds[0];
        StoredCheck storage check = checks.all[id];
        check.divisorIndex = 7;

        // Burn all 63 other Checks.
        for (uint i = 1; i < count;) {
            _burn(tokenIds[i]);

            unchecked { i++; }
        }

        // Notify final composite.
        emit Infinity(id, tokenIds[1:]);
    }

    function burn(uint256 tokenId) external virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);

        unchecked { checks.minted--; }
    }

    function colors(uint256 tokenId) external view returns (string[] memory, uint256[] memory)
    {
        return ChecksArt.colors(ChecksArt.getCheck(tokenId, checks), checks);
    }

    function svg(uint256 tokenId) external view returns (string memory) {
        _requireMinted(tokenId);

        return string(ChecksArt.generateSVG(tokenId, checks));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        return ChecksMetadata.tokenURI(tokenId, checks);
    }

    function totalSupply() public view returns (uint256) {
        return checks.minted - checks.burned;
    }

    function _multiTokenOperation(uint256[] calldata tokenIds, uint256[] calldata burnIds)
        internal pure returns (uint256 pairs)
    {
        pairs = tokenIds.length;
        require(pairs == burnIds.length, "Invalid number of tokens to composite");
    }

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

    function _sacrifice(uint256 tokenId, uint256 burnId) internal {
        (
            StoredCheck storage toKeep,
            StoredCheck storage toBurn,
            uint8 divisorIndex
        ) = _tokenOperation(tokenId, burnId);

        toKeep.seed = toBurn.seed;
        toKeep.gradients[divisorIndex] = toBurn.gradients[divisorIndex];
        toKeep.colorBands[divisorIndex] = toBurn.colorBands[divisorIndex];

        // Perform the burn
        _burn(burnId);

        // Notify replace
        emit IChecks.Sacrifice(burnId, tokenId);
    }

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
            // Need a randomizer for gene manipulation
            uint256 randomizer = Utils.seed(checks.burned);

            // We take the smallest gradient, or continue as random checks
            toKeep.gradients[toKeep.divisorIndex] = Utils.random(randomizer, 1, 100) > 80
                ? _min(toKeep.gradients[divisorIndex], toBurn.gradients[divisorIndex])
                : _minGt0(toKeep.gradients[divisorIndex], toBurn.gradients[divisorIndex]);

            // We always take the smaller color band when breeding
            // TODO: refactor to band averages
            toKeep.colorBands[toKeep.divisorIndex] = _min(
                toKeep.colorBands[divisorIndex],
                toBurn.colorBands[divisorIndex]
            );
        }

        // Perform the burn
        _burn(burnId);

        // Notify composite
        emit IChecks.Composite(tokenId, burnId, ChecksArt.DIVISORS()[toKeep.divisorIndex]);
    }

    // TODO: Move to utilities
    function _minGt0(uint8 one, uint8 two) internal pure returns (uint8) {
        return one > two
            ? two > 0
                ? two
                : one
            : two;
    }

    function _min(uint8 one, uint8 two) internal pure returns (uint8) {
        return one < two ? one : two;
    }

    function _avg(uint8 one, uint8 two) internal pure returns (uint8) {
        return (one & two) + (one ^ two) / 2;
    }
}
