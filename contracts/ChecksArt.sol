//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";
import "./Utilities.sol";
import "./IChecks.sol";

struct CheckRenderData {
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

library ChecksArt {
    string public constant CHECKS_PATH = 'M20 10.476c0-1.505-.833-2.81-2.046-3.428.147-.415.227-.862.227-1.334 0-2.104-1.629-3.807-3.636-3.807-.448 0-.876.08-1.272.238C12.684.87 11.438 0 10 0 8.562 0 7.319.873 6.727 2.143a3.434 3.434 0 0 0-1.272-.238c-2.01 0-3.636 1.705-3.636 3.81 0 .47.079.917.226 1.333C.833 7.667 0 8.97 0 10.476c0 1.424.745 2.665 1.85 3.32-.02.162-.031.324-.031.49 0 2.104 1.627 3.81 3.636 3.81.448 0 .876-.083 1.271-.239C7.316 19.127 8.561 20 10 20c1.44 0 2.683-.872 3.273-2.143.395.155.824.236 1.272.236 2.01 0 3.636-1.704 3.636-3.81 0-.165-.011-.327-.031-.488C19.252 13.141 20 11.9 20 10.477Zm-6.3-3.175-4.128 6.19a.713.713 0 0 1-.991.199l-.11-.09-2.3-2.3a.713.713 0 1 1 1.01-1.01l1.685 1.683 3.643-5.466a.715.715 0 0 1 1.19.793v.001Z';

        /// @dev Generate indexes for the color slots of its parent (root being the COLORS themselves).
    function colorIndexes(uint8 divisorIndex, IChecks.Check memory check, uint8[8] memory DIVISORS, IChecks.Data storage checks)
        internal view returns (uint256[] memory)
    {
        uint256 checksCount = DIVISORS[divisorIndex];
        uint256 possibleColorChoices = divisorIndex > 0 ? DIVISORS[divisorIndex - 1] * 2 : 80;

        uint256[] memory indexes = new uint256[](checksCount);
        for (uint i = 0; i < checksCount; i++) {
            indexes[i] = Utils.random(check.seed + i, 0, possibleColorChoices - 1);
        }

        if (divisorIndex > 0) {
            uint8 previousDivisor = divisorIndex - 1;

            uint256[] memory parentIndexes = colorIndexes(previousDivisor, check, DIVISORS, checks);

            IChecks.Check memory composited = checks.all[check.composite[previousDivisor]];
            uint256[] memory compositedIndexes = colorIndexes(previousDivisor, composited, DIVISORS, checks);

            // Replace random indices with parent / root color indices
            uint8 count = DIVISORS[previousDivisor];
            for (uint i = 0; i < DIVISORS[divisorIndex]; i++) {
                uint256 branchIndex = indexes[i] % count;
                indexes[i] = indexes[i] < count
                    ? parentIndexes[branchIndex]
                    : compositedIndexes[branchIndex];
            }
        }

        return indexes;
    }

    // function colors(IChecks.Check memory check, string[80] memory COLORS) public pure returns (string[] memory) {
    //     // A fully composited check has no color.
    //     if (check.checks == 0) {
    //         string[] memory zeroColors;
    //         zeroColors[0] = '#FFFFFF';
    //         return zeroColors;
    //     }

    //     // Fetch the indices on the original color mapping.
    //     uint256[] memory indexes = colorIndexes(check.divisorIndex, check, );

    //     // Map over to get the colors.
    //     string[] memory checkColors = new string[](check.checks);
    //     for (uint i = 0; i < indexes.length; i++) {
    //         checkColors[i] = COLORS[indexes[i]];
    //     }

    //     return checkColors;
    // }

    function tokenURI(uint256 tokenId, IChecks.Check memory check, string[80] memory COLORS) public pure returns (string memory) {
        bytes memory metadata = abi.encodePacked(
            '{',
                '"name": "Checks ', tokenId, '",',
                '"description": "This artwork may or may not be notable",',
                '"image": ',
                    '"data:image/svg+xml;base64,',
                    Base64.encode(generateSVG(check, COLORS)),
                    '"',
                '"animation_url": ',
                    '"data:text/html;base64,',
                    Base64.encode(generateHTML(check, COLORS)),
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

    function perRow(uint8 checks) public pure returns (uint8) {
        return checks == 80
            ? 8
            : checks >= 20 || checks == 4
                ? 4
                : checks == 10
                    ? 2
                    : 1;
    }

    function rowX(uint8 checks) public pure returns (uint16) {
        return checks <= 1 || checks == 5
            ? 312
            : checks == 10
                ? 276
                : 204;
    }

    function rowY(uint8 checks) public pure returns (uint16) {
        return checks >= 5 ? 168 : 312;
    }

    function fillAnimation(uint256 seed, string[80] memory COLORS) public pure returns (
        string memory fill,
        string memory animation
    ) {
        uint256 colorIndex = Utils.random(seed, 0, 79);
        fill = COLORS[colorIndex];
        bytes memory values;
        for (uint i = colorIndex; i < (colorIndex + 80); i++) {
            values = abi.encodePacked(values, COLORS[colorIndex % 80]);
        }

        return (fill, string(values));
    }

    function generateChecks(IChecks.Check memory check, string[80] memory COLORS) public pure returns (string memory) {
        uint8 checksCount = check.checks;
        uint32 seed = check.seed;

        // Positioning
        CheckRenderData memory data;
        data.scale = checksCount > 20 ? '1' : '2.8';
        data.spaceX = checksCount == 80 ? 36 : 72;
        data.spaceY = checksCount > 20 ? 36 : 72;
        data.perRow = perRow(checksCount);
        data.rowX = rowX(checksCount);
        data.rowY = rowY(checksCount);
        data.indent = checksCount == 40;

        // Animation
        data.duration = Utils.uint2str(checksCount*3);

        bytes memory checksBytes;
        for (uint8 i = 0; i < checksCount; i++) {
            // Positioning
            data.indexInRow = i % data.perRow;
            data.isNewRow = data.indexInRow == 0 && i > 0;
            if (data.isNewRow) {
                data.rowY += data.spaceY;
            }
            data.isIndented = data.indent && i % data.perRow == 0 ? 1 : 0;
            string memory translateX = Utils.uint2str(data.rowX + data.indexInRow * data.spaceX + data.isIndented * data.spaceX);
            string memory translateY = Utils.uint2str(data.rowY);

            // Animation
            (string memory fill, string memory animation) = fillAnimation(seed + checksCount + i, COLORS);

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

    function generateSVG(IChecks.Check memory check, string[80] memory COLORS) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<svg ',
                'viewBox="0 0 680 680" ',
                'fill="none" xmlns="http://www.w3.org/2000/svg" ',
                'style="width:100%;background:#EFEFEF;"',
            '>',
                '<rect width="680" height="680" fill="#EFEFEF" />',
                '<rect x="188" y="152" width="304" height="376" fill="white"/>',
                generateChecks(check, COLORS),
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

    function generateHTML(IChecks.Check memory check, string[80] memory COLORS) public pure returns (bytes memory) {
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
                generateSVG(check, COLORS),
            '</body>',
            '</html>'
        );
    }
}
