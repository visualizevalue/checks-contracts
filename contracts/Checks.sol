// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import './IChecksEdition.sol';
import './IChecks.sol';
import './ChecksArt.sol';
import "./Utilities.sol";

import "hardhat/console.sol";

contract Checks is IChecks, ERC721 {
    IChecksEdition public editionChecks;

    string[80] public COLORS = [
        '#DB395E', '#525EAA', '#977A31', '#2E668B', '#33758D', '#4068C1', '#F2A43A', '#ED7C30',
        '#F9DA4A', '#322F92', '#5C83CB', '#FBEA5B', '#E73E53', '#DA3321', '#9AD9FB', '#77D3DE',
        '#D6F4E1', '#F0A0CA', '#F2B341', '#2E4985', '#25438C', '#EB5A2A', '#DB4D58', '#5FCD8C',
        '#FAE663', '#8A2235', '#A4C8EE', '#81D1EC', '#D97D2E', '#F9DB49', '#85C33C', '#EA3A2D',
        '#5A9F3E', '#EF8C37', '#F7CA57', '#EB4429', '#A7DDF9', '#F2A93B', '#F2A840', '#DE3237',
        '#602263', '#EC7368', '#D5332F', '#F6CBA6', '#F09837', '#F9DA4D', '#5ABAD3', '#3E8BA3',
        '#C7EDF2', '#E8424E', '#B1EFC9', '#93CF98', '#2F2243', '#2D5352', '#F7DD9B', '#6A552A',
        '#D1DF4F', '#4D3658', '#EA5B33', '#5FC9BF', '#7A2520', '#B82C36', '#F2A93C', '#4291A8',
        '#F4BDBE', '#FAE272', '#EF8933', '#3B2F39', '#ABDD45', '#4AA392', '#C23532', '#F6CB45',
        '#6D2F22', '#535687', '#EE837D', '#E0C963', '#9DEFBF', '#60B1F4', '#EE828F', '#7A5AB4'
    ];

    // TODO 0 = infinity, maybe call `zero` `infinity`
    uint8[8] public DIVISORS = [ 80, 40, 20, 10, 5, 4, 1, 0 ];

    Data checks;

    constructor() ERC721("Checks", "Check") {
        // Link Checks to the Edition Contract
        editionChecks = IChecksEdition(0x34eEBEE6942d8Def3c125458D1a86e0A897fd6f9);
    }

    function mint(uint256[] calldata tokenIds) public {
        uint256 count = tokenIds.length;

        // Make sure we have the Editions burn approval from the minter.
        require(editionChecks.isApprovedForAll(msg.sender, address(this)), "Edition burn not approved");

        // Make sure all referenced Editions are owned by or approved to the minter.
        for (uint i = 0; i < count; i++) {
            require(editionChecks.ownerOf(tokenIds[i]) == msg.sender, "Minter not the owner");
        }

        // Burn the Editions for the given tokenIds & mint the Originals.
        for (uint i = 0; i < count; i++) {
            uint256 id = tokenIds[i];
            editionChecks.burn(id);
            Check storage check = checks.all[id];
            check.checks = 80;
            check.divisorIndex = 0;
            check.seed = uint32(Utils.random(uint256(keccak256(abi.encodePacked(msg.sender, id))), 0, 4294967294)); // max is the highest uint32
            _mint(msg.sender, id);
        }
    }

    function getCheck(uint256 tokenId) external view returns (Check memory) {
        _requireMinted(tokenId);

        console.log('getCheck ownerOf(tokenId)');
        console.log(ownerOf(tokenId));

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
        require(toKeep.checks == toBurn.checks, "Can only composite from same type");
        require(toKeep.checks > 0, "Can't composite a black check");

        // Composite our check
        toKeep.composite[toKeep.divisorIndex] = uint16(burnId);
        toKeep.divisorIndex += 1;
        toKeep.checks = DIVISORS[toKeep.divisorIndex];

        // Perform the burn
        console.log('burning');
        console.log(burnId);
        console.log(ownerOf(burnId));
        _burn(burnId);

        // Notify composite
        emit IChecks.Composite(tokenId, burnId, toKeep.checks);
    }

    function compositeMany(uint256[] calldata tokenIds, uint256[] calldata burnIds) public {
        uint256 pairs = tokenIds.length;
        require(pairs == burnIds.length, "Invalid number of tokens to composite");

        for (uint i = 0; i < pairs; i++) {
            composite(tokenIds[i], burnIds[i]);
        }
    }

    function zero(uint256[] calldata tokenIds) public {
        uint256 count = tokenIds.length;
        require(count == 64, "Final composite requires 64 single Checks");
        for (uint i = 0; i < count; i++) {
            require(checks.all[tokenIds[i]].checks == 1, "Non-single Check used");
        }

        // Complete final composite.
        uint256 id = tokenIds[0];
        Check storage check = checks.all[id];
        check.checks = 0;
        check.divisorIndex = 7;

        // Burn all 63 other Checks.
        for (uint i = 1; i < count; i++) {
            _burn(tokenIds[i]);
        }

        // Notify final composite.
        emit Zero(id, tokenIds[1:]);
    }

    function colorIndexes(uint256 tokenId)
        external view returns (uint256[] memory indexes)
    {
        Check memory check = checks.all[tokenId];
        return ChecksArt.colorIndexes(check.divisorIndex, check, DIVISORS, checks);
    }

    function colors(uint256 tokenId) external view returns (string[] memory)
    {
        Check memory check = checks.all[tokenId];
        return ChecksArt.colors(check, DIVISORS, checks, COLORS);
    }

    // function tokenURI(uint256 tokenId) public view override returns (string memory) {
    //     _requireMinted(tokenId);

    //     return ChecksArt.tokenURI(tokenId, checks.all[tokenId], COLORS);
    // }

    function svg(uint256 tokenId) external view returns (string memory) {
        console.log(tokenId);
        _requireMinted(tokenId);
        console.log(tokenId);

        return string(ChecksArt.generateSVG(checks.all[tokenId], COLORS));
    }
}
