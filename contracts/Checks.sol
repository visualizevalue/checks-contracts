// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import './IChecksEdition.sol';
import './IChecks.sol';
import './ChecksArt.sol';
import "./Utilities.sol";

// import "hardhat/console.sol";

contract Checks is IChecks, ERC721 {
    IChecksEdition public editionChecks;

    Checks checks;

    constructor() ERC721("Checks", "Check") {
        // Link Checks to the Edition Contract
        editionChecks = IChecksEdition(0x34eEBEE6942d8Def3c125458D1a86e0A897fd6f9);
    }

    function mint(uint256[] calldata tokenIds) public {
        uint256 count = tokenIds.length;

        // Make sure we have the Editions burn approval from the minter.
        require(editionChecks.isApprovedForAll(msg.sender, address(this)), "Edition burn not approved");

        // Make sure all referenced Editions are owned by or approved to the minter.
        for (uint i = 0; i < count;) {
            require(editionChecks.ownerOf(tokenIds[i]) == msg.sender, "Minter not the owner");

            unchecked { i++; }
        }

        // Burn the Editions for the given tokenIds & mint the Originals.
        for (uint i = 0; i < count;) {
            uint256 id = tokenIds[i];
            editionChecks.burn(id);
            Check storage check = checks.all[id];
            check.checksCount = 80;
            check.divisorIndex = 0;
            check.seed = uint32(Utils.random(uint256(keccak256(abi.encodePacked(msg.sender, id))), 0, 4294967294)); // max is the highest uint32
            check.colorBand = 10;
            // check.gradient = 1; // TODO: Gradient steps
            check.gradient = 8; // TODO: Gradient steps;
            check.speed = 8;
            // TODO: Gradient Directionality
            _mint(msg.sender, id);

            unchecked { i++; }
        }
    }

    function getCheck(uint256 tokenId) external view returns (Check memory) {
        _requireMinted(tokenId);

        return checks.all[tokenId];
    }

    function composite(uint256 tokenId, uint256 burnId) public {
        require(tokenId != burnId, "Can't composit the same token");
        require(
            _isApprovedOrOwner(msg.sender, tokenId) && _isApprovedOrOwner(msg.sender, burnId),
            "Not the owner or approved"
        );

        Check storage toKeep = checks.all[tokenId];
        Check storage toBurn = checks.all[tokenId];
        require(toKeep.checksCount == toBurn.checksCount, "Can only composite from same type");
        require(toKeep.checksCount > 0, "Can't composite a black check");

        // Composite our check
        toKeep.composite[toKeep.divisorIndex] = uint16(burnId);
        toKeep.divisorIndex += 1;
        toKeep.checksCount = ChecksArt.DIVISORS()[toKeep.divisorIndex];
        // TODO: gradient breeding

        // Perform the burn
        _burn(burnId);

        // Notify composite
        emit IChecks.Composite(tokenId, burnId, toKeep.checksCount);
    }

    function compositeMany(uint256[] calldata tokenIds, uint256[] calldata burnIds) public {
        uint256 pairs = tokenIds.length;
        require(pairs == burnIds.length, "Invalid number of tokens to composite");

        for (uint i = 0; i < pairs;) {
            composite(tokenIds[i], burnIds[i]);

            unchecked { i++; }
        }
    }

    function infinity(uint256[] calldata tokenIds) public {
        uint256 count = tokenIds.length;
        require(count == 64, "Final composite requires 64 single Checks");
        for (uint i = 0; i < count;) {
            require(checks.all[tokenIds[i]].checksCount == 1, "Non-single Check used");

            unchecked { i++; }
        }

        // Complete final composite.
        uint256 id = tokenIds[0];
        Check storage check = checks.all[id];
        check.checksCount = 0;
        check.divisorIndex = 7;

        // Burn all 63 other Checks.
        for (uint i = 1; i < count;) {
            _burn(tokenIds[i]);

            unchecked { i++; }
        }

        // Notify final composite.
        emit Infinity(id, tokenIds[1:]);
    }

    function colors(uint256 tokenId) external view returns (string[] memory, uint256[] memory)
    {
        Check memory check = checks.all[tokenId];
        return ChecksArt.colors(check, checks);
    }

    function svg(uint256 tokenId) external view returns (string memory) {
        _requireMinted(tokenId);

        return string(ChecksArt.generateSVG(checks.all[tokenId], checks));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        return ChecksArt.tokenURI(tokenId, checks.all[tokenId], checks);
    }
}
