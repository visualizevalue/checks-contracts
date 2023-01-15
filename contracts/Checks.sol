// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./Utilities.sol";

contract Checks is ERC721 {
    ERC721Burnable public editionChecks;

    event Composite(
        uint256 indexed tokenId,
        uint256 indexed burnedId,
        uint8 indexed checks
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

    string public CHECKS_PATH = 'M20 10.476c0-1.505-.833-2.81-2.046-3.428.147-.415.227-.862.227-1.334 0-2.104-1.629-3.807-3.636-3.807-.448 0-.876.08-1.272.238C12.684.87 11.438 0 10 0 8.562 0 7.319.873 6.727 2.143a3.434 3.434 0 0 0-1.272-.238c-2.01 0-3.636 1.705-3.636 3.81 0 .47.079.917.226 1.333C.833 7.667 0 8.97 0 10.476c0 1.424.745 2.665 1.85 3.32-.02.162-.031.324-.031.49 0 2.104 1.627 3.81 3.636 3.81.448 0 .876-.083 1.271-.239C7.316 19.127 8.561 20 10 20c1.44 0 2.683-.872 3.273-2.143.395.155.824.236 1.272.236 2.01 0 3.636-1.704 3.636-3.81 0-.165-.011-.327-.031-.488C19.252 13.141 20 11.9 20 10.477Zm-6.3-3.175-4.128 6.19a.713.713 0 0 1-.991.199l-.11-.09-2.3-2.3a.713.713 0 1 1 1.01-1.01l1.685 1.683 3.643-5.466a.715.715 0 0 1 1.19.793v.001Z';

    uint8[8] public TYPES = [ 80, 40, 20, 10, 5, 4, 1, 0 ];

    struct Check {
        uint8 checks; // How many checks are in this
        uint8 checksTypeIndex; // How many checks are in this
        uint16 composite; // The tokenId that was merged into this one
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
        require(editionChecks.isApprovedForAll(msg.sender, address(this)), "Edition burn not approved.");

        // Make sure all referenced Editions are owned by or approved to the minter.
        for (uint i = 0; i < count; i++) {
            require(editionChecks.ownerOf(tokenIds[i]) == msg.sender, "Minter not the owner.");
        }

        // Burn the Editions for the given tokenIds & mint the Originals.
        for (uint i = 0; i < count; i++) {
            uint256 id = tokenIds[i];
            editionChecks.burn(id);
            uint256 seed = uint256(keccak256(abi.encodePacked(msg.sender, id)));
            _checks[id] = Check(80, 0, 0, uint32(seed));
            _mint(msg.sender, id);
        }
    }

    function composite(uint256 tokenId, uint256 burnId) public {
        require(tokenId != burnId, "Can't composit the same token.");
        require(
            _isApprovedOrOwner(msg.sender, tokenId) && _isApprovedOrOwner(msg.sender, burnId),
            "Not the owner or approved."
        );

        Check memory toKeep = _checks[tokenId];
        Check memory toBurn = _checks[tokenId];
        require(toKeep.checks == toBurn.checks, "Can only composite from same type.");
        require(toKeep.checks > 0, "Can't composite a black check.");

        // Composite our check
        toKeep.checksTypeIndex += 1;
        toKeep.checks = TYPES[toKeep.checksTypeIndex];
        toKeep.seed = toKeep.seed + toBurn.seed;
        toKeep.composite = uint16(burnId);

        // Perform the burn
        _burn(burnId);

        // Notify composite
        emit Composite(tokenId, burnId, toKeep.checks);
    }

    function compositeMany(uint256[] calldata tokenIds, uint256[] calldata burnIds) public {
        uint256 pairs = tokenIds.length;
        require(pairs == burnIds.length, "Invalid number of tokens to composite.");

        for (uint i = 0; i < pairs; i++) {
            composite(tokenIds[i], burnIds[i]);
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        Check memory check = _checks[tokenId];

        bytes memory metadata = abi.encodePacked(
            '{',
                '"name": "Checks ', tokenId, '",',
                '"description": "This artwork may or may not be notable.",',
                '"image": ',
                    '"data:image/svg+xml;base64,',
                    Base64.encode(_generateSVG(tokenId, check)),
                    '"',
                '"animation_url": ',
                    '"data:text/html;base64,',
                    Base64.encode(_generateHTML(tokenId, check)),
                    '"',
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(metadata)
            )
        );
    }

    function generateSVG(uint256 tokenId) public view returns (string memory) {
        _requireMinted(tokenId);

        return string(_generateSVG(tokenId, _checks[tokenId]));
    }

    function _perRow(uint8 checks) internal pure returns (uint8) {
        return checks == 80
            ? 8
            : checks >= 20 || checks == 4
                ? 4
                : checks == 10
                    ? 2
                    : 1;
    }

    function _rowX(uint8 checks) internal pure returns (uint16) {
        return checks <= 1 || checks == 5
            ? 312
            : checks == 10
                ? 276
                : 204;
    }

    function _rowY(uint8 checks) internal pure returns (uint16) {
        return checks >= 5 ? 168 : 312;
    }

    function _fillAnimation(uint256 seed) internal view returns (
        string memory fill,
        string memory animation
    ) {
        uint256 colorIndex = utils.random(seed, 0, 79);
        fill = COLORS[colorIndex];
        bytes memory fillAnimation;
        for (uint i = colorIndex; i < (colorIndex + 80); i++) {
            fillAnimation = abi.encodePacked(fillAnimation, COLORS[colorIndex % 80]);
        }

        return (fill, string(fillAnimation));
    }

    // /// @dev generate indexes from both this and its composite check
    // function _colorIndexes(uint256 tokenId, Check memory check)
    //     internal view returns (uint256 count, uint256[] memory indexes)
    // {
    //     uint256 checksCount = check.checks;
    //     uint256 possibleColors = check.composite > 0 ? checksCount * 2 : checksCount;
    //     // uint256[checksCount] memory colorIndexes;
    //     uint256[] memory colorIndexes;

    //     for (uint i = 0; i < checksCount; i++) {
    //         colorIndexes[i] = utils.random(tokenId + check.seed + i, 0, possibleColors - 1);
    //     }

    //     return (possibleColors, colorIndexes);
    // }

    // function _colors(uint256 tokenId, Check memory check) internal view returns (string[] memory) {
    //     (uint256 count, uint256[] memory indexes) = _colorIndexes(tokenId, check);

    //     // string[check.checks] memory colors;
    //     string[] memory colors;
    //     for (uint i = 0; i < check.checks; i++) {
    //         colors[i] = COLORS[indexes[i]];
    //     }

    //     return colors;
    // }

    struct CheckRenderer {
        string duration;
        string scale;
        uint16 rowX;
        uint16 rowY;
        uint8 spaceX;
        uint8 spaceY;
        uint8 perRow;
        uint8 indexInRow;
        uint8 isIndented;
        bool indent;
        bool isNewRow;
    }

    function _generateChecks(uint256 tokenId, Check memory check) internal view returns (string memory) {
        uint8 checksCount = check.checks;
        uint32 seed = check.seed;

        // Positioning
        CheckRenderer memory data;
        data.scale = checksCount > 20 ? '1' : '2.8';
        data.spaceX = checksCount == 80 ? 36 : 72;
        data.spaceY = checksCount > 20 ? 36 : 72;
        data.perRow = _perRow(checksCount);
        data.rowX = _rowX(checksCount);
        data.rowY = _rowY(checksCount);
        data.indent = checksCount == 40;

        // Animation
        data.duration = utils.uint2str(checksCount*3);

        bytes memory checksBytes;
        for (uint8 i = 0; i < checksCount; i++) {
            // Positioning
            data.indexInRow = i % data.perRow;
            data.isNewRow = data.indexInRow == 0 && i > 0;
            if (data.isNewRow) {
                data.rowY += data.spaceY;
            }
            data.isIndented = data.indent && i % data.perRow == 0 ? 1 : 0;
            string memory translateX = utils.uint2str(data.rowX + data.indexInRow * data.spaceX + data.isIndented * data.spaceX);
            string memory translateY = utils.uint2str(data.rowY);

            // Animation
            (string memory fill, string memory animation) = _fillAnimation(tokenId + seed + i);

            checksBytes = abi.encodePacked(checksBytes, abi.encodePacked(
                '<g ',
                    'transform="translate(', translateX, ', ', translateY, ')"',
                '>',
                    '<path transform="scale(',data.scale,')" fill="',fill,'" d="',CHECKS_PATH,'">',
                        '<animate ',
                            'attributeName="fill" values="',animation,'" ',
                            'dur="',data.duration,'s" begin="animation.begin" ',
                            'repeatCount="indefinite" ',
                        '/>',
                    '</path>',
                '</g>'
            ));
        }

        return string(checksBytes);
    }

    function _generateSVG(uint256 tokenId, Check memory check) internal view returns (bytes memory) {
        return abi.encodePacked(
            '<svg ',
                'viewBox="0 0 680 680" ',
                'fill="none" xmlns="http://www.w3.org/2000/svg" ',
                'style="width:100%;background:#EFEFEF;"',
            '>',
                '<rect width="680" height="680" fill="#EFEFEF" />',
                '<rect x="188" y="152" width="304" height="376" fill="white"/>',
                _generateChecks(tokenId, check),
                '<rect width="680" height="680" fill="transparent">',
                    '<animate',
                        'attributeName="width"',
                        'from="680"',
                        'to="0"',
                        'dur="0.2s"',
                        'begin="click"',
                        'fill="freeze"',
                        'id="animation"',
                    '/>',
                '</rect>',
            '</svg>'
        );
    }

    function _generateHTML(uint256 tokenId, Check memory check) internal view returns (bytes memory) {
        return abi.encodePacked(
            '<!DOCTYPE html>',
            '<html lang="en">',
            '<head>',
                '<meta charset="UTF-8">',
                '<meta http-equiv="X-UA-Compatible" content="IE=edge">',
                '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
                '<title>Check #1234</title>',
                '<style>',
                    'html,',
                    'body {',
                        'margin: 0;',
                        'background: #EFEFEF;',
                    '}',
                    'svg {',
                        'max-width: 100vw;',
                        'max-height: 100vh;',
                    '}',
                '</style>',
            '</head>',
            '<body>',
                _generateSVG(tokenId, check),
            '</body>',
            '</html>'
        );
    }
}
