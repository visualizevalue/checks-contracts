// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
// import "@openzeppelin/contracts/Utils/Base64.sol";

import "./Utilities.sol";

import "hardhat/console.sol";

contract Checks is ERC721 {
    ERC721Burnable public editionChecks;

    event Composite(
        uint256 indexed tokenId,
        uint256 indexed burnedId,
        uint8 indexed checks
    );

    event Zero(
        uint256 indexed tokenId,
        uint256[] indexed burnedIds
    );

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

    uint8[8] public LEVELS = [ 80, 40, 20, 10, 5, 4, 1, 0 ];

    struct Check {
        uint8 checks; // How many checks are in this
        uint8 level; // How many checks are in this
        uint16[7] composite; // The tokenIds that were merged into this one
        uint32 seed; // Seed for the color randomisation
    }

    mapping(uint256 => Check) private _checks;

    constructor() ERC721("Checks", "Check") {
        // Link Checks to the Edition Contract
        editionChecks = ERC721Burnable(0x34eEBEE6942d8Def3c125458D1a86e0A897fd6f9);
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
            Check storage check = _checks[id];
            check.checks = 80;
            check.level = 0;
            check.seed = uint32(Utils.random(uint256(keccak256(abi.encodePacked(msg.sender, id))), 0, 4294967294)); // max is the highest uint32
            _mint(msg.sender, id);
        }
    }

    function getCheck(uint256 tokenId) external view returns (Check memory) {
        _requireMinted(tokenId);

        return _checks[tokenId];
    }

    function composite(uint256 tokenId, uint256 burnId) public {
        require(tokenId != burnId, "Can't composit the same token");
        require(
            _isApprovedOrOwner(msg.sender, tokenId) && _isApprovedOrOwner(msg.sender, burnId),
            "Not the owner or approved"
        );

        Check storage toKeep = _checks[tokenId];
        Check storage toBurn = _checks[tokenId];
        require(toKeep.checks == toBurn.checks, "Can only composite from same type");
        require(toKeep.checks > 0, "Can't composite a black check");

        // Composite our check
        toKeep.composite[toKeep.level] = uint16(burnId);
        toKeep.level += 1;
        toKeep.checks = LEVELS[toKeep.level];

        // Perform the burn
        _burn(burnId);

        // Notify composite
        emit Composite(tokenId, burnId, toKeep.checks);
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
            require(_checks[tokenIds[i]].checks == 1, "Non-single Check used");
        }

        // Complete final composite.
        uint256 id = tokenIds[0];
        Check storage check = _checks[id];
        check.checks = 0;
        check.level = 7;

        // Burn all 63 other Checks.
        for (uint i = 1; i < count; i++) {
            _burn(tokenIds[i]);
        }

        // Notify final composite.
        emit Zero(id, tokenIds[1:]);
    }

    /// @dev Generate indexes for the color slots of its parent (root being the COLORS themselves).
    function _colorIndexes(Check memory check)
        internal view returns (uint256, uint256[] memory)
    {
        uint256 checksCount = check.checks;
        uint256 possibleColors = check.level > 0 ? LEVELS[check.level - 1] * 2 : 80;

        uint256[] memory indexes = new uint256[](checksCount);
        for (uint i = 0; i < checksCount; i++) {
            indexes[i] = Utils.random(check.seed + i, 0, possibleColors - 1);
        }

        return (possibleColors, indexes);
    }

    function colorIndexes(uint256 tokenId)
        external view returns (uint256 count, uint256[] memory indexes)
    {
        return _colorIndexes(_checks[tokenId]);
    }

    function colors(uint256 tokenId)
        external view returns (string[] memory)
    {
        Check memory check = _checks[tokenId];
        (uint256 count, uint256[] memory indexes) = _colorIndexes(check);

        if (check.composite[check.level] > 0) {

        }

        string[] memory checkColors = new string[](check.checks);
        for (uint i = 0; i < indexes.length; i++) {
            // FIXME nah
            checkColors[i] = COLORS[indexes[i]];
            console.log(checkColors[i]);
        }

        return checkColors;
    }

    // function tokenURI(uint256 tokenId) public view override returns (string memory) {
    //     _requireMinted(tokenId);

    //     Check memory check = _checks[tokenId];

    //     bytes memory metadata = abi.encodePacked(
    //         '{',
    //             '"name": "Checks ', tokenId, '",',
    //             '"description": "This artwork may or may not be notable",',
    //             '"image": ',
    //                 '"data:image/svg+xml;base64,',
    //                 Base64.encode(_generateSVG(tokenId, check)),
    //                 '"',
    //             '"animation_url": ',
    //                 '"data:text/html;base64,',
    //                 Base64.encode(_generateHTML(tokenId, check)),
    //                 '"',
    //         '}'
    //     );

    //     return string(
    //         abi.encodePacked(
    //             "data:application/json;base64,",
    //             Base64.encode(metadata)
    //         )
    //     );
    // }

    // function generateSVG(uint256 tokenId) public view returns (string memory) {
    //     _requireMinted(tokenId);

    //     return string(_generateSVG(tokenId, _checks[tokenId]));
    // }

    // function _perRow(uint8 checks) internal pure returns (uint8) {
    //     return checks == 80
    //         ? 8
    //         : checks >= 20 || checks == 4
    //             ? 4
    //             : checks == 10
    //                 ? 2
    //                 : 1;
    // }

    // function _rowX(uint8 checks) internal pure returns (uint16) {
    //     return checks <= 1 || checks == 5
    //         ? 312
    //         : checks == 10
    //             ? 276
    //             : 204;
    // }

    // function _rowY(uint8 checks) internal pure returns (uint16) {
    //     return checks >= 5 ? 168 : 312;
    // }

    // function _fillAnimation(uint256 seed) internal view returns (
    //     string memory fill,
    //     string memory animation
    // ) {
    //     uint256 colorIndex = Utils.random(seed, 0, 79);
    //     fill = COLORS[colorIndex];
    //     bytes memory fillAnimation;
    //     for (uint i = colorIndex; i < (colorIndex + 80); i++) {
    //         fillAnimation = abi.encodePacked(fillAnimation, COLORS[colorIndex % 80]);
    //     }

    //     return (fill, string(fillAnimation));
    // }

    // // function _colors(uint256 tokenId, Check memory check) internal view returns (string[] memory) {
    // //     (uint256 count, uint256[] memory indexes) = _colorIndexes(tokenId, check);

    // //     // string[check.checks] memory colors;
    // //     string[] memory colors;
    // //     for (uint i = 0; i < check.checks; i++) {
    // //         colors[i] = COLORS[indexes[i]];
    // //     }

    // //     return colors;
    // // }

    // struct CheckRenderData {
    //     string duration;
    //     string scale;
    //     uint16 rowX;
    //     uint16 rowY;
    //     uint8 spaceX;
    //     uint8 spaceY;
    //     uint8 perRow;
    //     uint8 indexInRow;
    //     uint8 isIndented;
    //     bool indent;
    //     bool isNewRow;
    // }

    // function _generateChecks(uint256 tokenId, Check memory check) internal view returns (string memory) {
    //     uint8 checksCount = check.checks;
    //     uint32 seed = check.seed;

    //     // Positioning
    //     CheckRenderData memory data;
    //     data.scale = checksCount > 20 ? '1' : '2.8';
    //     data.spaceX = checksCount == 80 ? 36 : 72;
    //     data.spaceY = checksCount > 20 ? 36 : 72;
    //     data.perRow = _perRow(checksCount);
    //     data.rowX = _rowX(checksCount);
    //     data.rowY = _rowY(checksCount);
    //     data.indent = checksCount == 40;

    //     // Animation
    //     data.duration = Utils.uint2str(checksCount*3);

    //     bytes memory checksBytes;
    //     for (uint8 i = 0; i < checksCount; i++) {
    //         // Positioning
    //         data.indexInRow = i % data.perRow;
    //         data.isNewRow = data.indexInRow == 0 && i > 0;
    //         if (data.isNewRow) {
    //             data.rowY += data.spaceY;
    //         }
    //         data.isIndented = data.indent && i % data.perRow == 0 ? 1 : 0;
    //         string memory translateX = Utils.uint2str(data.rowX + data.indexInRow * data.spaceX + data.isIndented * data.spaceX);
    //         string memory translateY = Utils.uint2str(data.rowY);

    //         // Animation
    //         (string memory fill, string memory animation) = _fillAnimation(seed + checksCount + i);

    //         checksBytes = abi.encodePacked(checksBytes, abi.encodePacked(
    //             '<g ',
    //                 'transform="translate(', translateX, ', ', translateY, ')"',
    //             '>',
    //                 '<path transform="scale(',data.scale,')" fill="',fill,'" d="',CHECKS_PATH,'">',
    //                     '<animate ',
    //                         'attributeName="fill" values="',animation,'" ',
    //                         'dur="',data.duration,'s" begin="animation.begin" ',
    //                         'repeatCount="indefinite" ',
    //                     '/>',
    //                 '</path>',
    //             '</g>'
    //         ));
    //     }

    //     return string(checksBytes);
    // }

    // function _generateSVG(uint256 tokenId, Check memory check) internal view returns (bytes memory) {
    //     return abi.encodePacked(
    //         '<svg ',
    //             'viewBox="0 0 680 680" ',
    //             'fill="none" xmlns="http://www.w3.org/2000/svg" ',
    //             'style="width:100%;background:#EFEFEF;"',
    //         '>',
    //             '<rect width="680" height="680" fill="#EFEFEF" />',
    //             '<rect x="188" y="152" width="304" height="376" fill="white"/>',
    //             _generateChecks(tokenId, check),
    //             '<rect width="680" height="680" fill="transparent">',
    //                 '<animate',
    //                     'attributeName="width"',
    //                     'from="680"',
    //                     'to="0"',
    //                     'dur="0.2s"',
    //                     'begin="click"',
    //                     'fill="freeze"',
    //                     'id="animation"',
    //                 '/>',
    //             '</rect>',
    //         '</svg>'
    //     );
    // }

    // function _generateHTML(uint256 tokenId, Check memory check) internal view returns (bytes memory) {
    //     return abi.encodePacked(
    //         '<!DOCTYPE html>',
    //         '<html lang="en">',
    //         '<head>',
    //             '<meta charset="UTF-8">',
    //             '<meta http-equiv="X-UA-Compatible" content="IE=edge">',
    //             '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
    //             '<title>Check #1234</title>',
    //             '<style>',
    //                 'html,',
    //                 'body {',
    //                     'margin: 0;',
    //                     'background: #EFEFEF;',
    //                 '}',
    //                 'svg {',
    //                     'max-width: 100vw;',
    //                     'max-height: 100vh;',
    //                 '}',
    //             '</style>',
    //         '</head>',
    //         '<body>',
    //             _generateSVG(tokenId, check),
    //         '</body>',
    //         '</html>'
    //     );
    // }
}
