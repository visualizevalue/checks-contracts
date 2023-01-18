//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";
import "./Utilities.sol";
import "./IChecks.sol";

import "hardhat/console.sol";

struct CheckRenderData {
    string[] colors;
    uint256[] colorIndexes;
    string duration;
    string scale;
    uint32 seed;
    uint16 rowX;
    uint16 rowY;
    uint8 checksCount;
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

    function COLORS() public pure returns (string[81] memory) {
        return [
            '#DB395E', '#525EAA', '#977A31', '#2E668B', '#33758D', '#4068C1', '#F2A43A', '#ED7C30',
            '#F9DA4A', '#322F92', '#5C83CB', '#FBEA5B', '#E73E53', '#DA3321', '#9AD9FB', '#77D3DE',
            '#D6F4E1', '#F0A0CA', '#F2B341', '#2E4985', '#25438C', '#EB5A2A', '#DB4D58', '#5FCD8C',
            '#FAE663', '#8A2235', '#A4C8EE', '#81D1EC', '#D97D2E', '#F9DB49', '#85C33C', '#EA3A2D',
            '#5A9F3E', '#EF8C37', '#F7CA57', '#EB4429', '#A7DDF9', '#F2A93B', '#F2A840', '#DE3237',
            '#602263', '#EC7368', '#D5332F', '#F6CBA6', '#F09837', '#F9DA4D', '#5ABAD3', '#3E8BA3',
            '#C7EDF2', '#E8424E', '#B1EFC9', '#93CF98', '#2F2243', '#2D5352', '#F7DD9B', '#6A552A',
            '#D1DF4F', '#4D3658', '#EA5B33', '#5FC9BF', '#7A2520', '#B82C36', '#F2A93C', '#4291A8',
            '#F4BDBE', '#FAE272', '#EF8933', '#3B2F39', '#ABDD45', '#4AA392', '#C23532', '#F6CB45',
            '#6D2F22', '#535687', '#EE837D', '#E0C963', '#9DEFBF', '#60B1F4', '#EE828F', '#7A5AB4',
            '#FFF'
        ];
    }

    /// @dev Generate indexes for the color slots of its parent (root being the COLORS themselves).
    function colorIndexes(uint8 divisorIndex, IChecks.Check memory check, uint8[8] memory DIVISORS, IChecks.Data storage checks)
        public view returns (uint256[] memory)
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

    function colors(
        IChecks.Check memory check, uint8[8] memory DIVISORS, IChecks.Data storage checks
    ) public view returns (string[] memory, uint256[] memory) {
        // A fully composited check has no color.
        if (check.checks == 0) {
            string[] memory zeroColors;
            zeroColors[0] = COLORS()[80];
            return (zeroColors, new uint256[](80));
        }

        // Fetch the indices on the original color mapping.
        uint256[] memory indexes = colorIndexes(check.divisorIndex, check, DIVISORS, checks);

        // Map over to get the colors.
        string[] memory checkColors = new string[](check.checks);
        string[81] memory allColors = COLORS();
        for (uint i = 0; i < indexes.length; i++) {
            checkColors[i] = allColors[indexes[i]];
        }

        return (checkColors, indexes);
    }

    // function tokenURI(uint256 tokenId, IChecks.Check memory check, string[81] memory COLORS) public pure returns (string memory) {
    //     bytes memory metadata = abi.encodePacked(
    //         '{',
    //             '"name": "Checks ', tokenId, '",',
    //             '"description": "This artwork may or may not be notable",',
    //             '"image": ',
    //                 '"data:image/svg+xml;base64,',
    //                 Base64.encode(generateSVG(check, COLORS)),
    //                 '"',
    //             '"animation_url": ',
    //                 '"data:text/html;base64,',
    //                 Base64.encode(generateHTML(check, COLORS)),
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

    function fillAnimation(CheckRenderData memory data, uint8 offset) public pure returns (
        string memory animation
    ) {
        bytes memory values;
        // for (uint i = 0; i < data.checksCount; i++) {
        for (uint i = offset; i < offset + 10; i++) {
            values = abi.encodePacked(values, data.colors[i % 80], ';');
        }

        // Add initial color as last one for smooth animations
        values = abi.encodePacked(values, data.colors[offset]);

        return string(values);
    }

    function fillAnimation() public pure returns (
        string memory animation
    ) {
        string[81] memory colors_ = COLORS();

        bytes memory values;
        for (uint i = 0; i < 80; i++) {
            values = abi.encodePacked(values, colors_[i], ';');
        }

        // Add initial color as last one for smooth animations
        values = abi.encodePacked(values, colors_[0]);

        return string(values);
    }

    function generateChecks(CheckRenderData memory data) public view returns (string memory) {
        bytes memory checksBytes;
        for (uint8 i = 0; i < data.checksCount; i++) {
            // Row Positioning
            data.indexInRow = i % data.perRow;
            data.isNewRow = data.indexInRow == 0 && i > 0;

            // Offsets
            if (data.isNewRow) data.rowY += data.spaceY;
            if (data.isNewRow && data.indent) {
                if (i == 0) {
                    data.rowX += data.spaceX / 2;
                }

                if (i % (data.perRow * 2) == 0) {
                    data.rowX -= data.spaceX / 2;
                } else {
                    data.rowX += data.spaceX / 2;
                }
            }
            string memory translateX = Utils.uint2str(data.rowX + data.indexInRow * data.spaceX);
            string memory translateY = Utils.uint2str(data.rowY);

            // Color & Animation
            console.log('HEEERREEEE!!!');
            console.log(data.seed);
            console.log(data.checksCount);
            console.log(i);
            console.log(data.seed + data.checksCount + i);
            // (string memory fill, string memory animation) = fillAnimation(data.seed + data.checksCount + i);
            // (string memory fill,) = fillAnimation(data.seed + data.checksCount + i, COLORS);
            console.log('PASSEDHEEERREEEE!!!');

            checksBytes = abi.encodePacked(checksBytes, abi.encodePacked(
                '<g transform="translate(', translateX, ', ', translateY, ')">',
                    // '<path transform="scale(',data.scale,')" fill="',fill,'" d="',CHECKS_PATH,'">',
                    '<use href="#check" transform="scale(',data.scale,')" fill="',data.colors[i],'">',
                        '<use href="#colors" begin="animation.begin -', data.colorIndexes[0] * 3,'s" />',
                            // 'attributeName="fill" values="',fillAnimation(data, i),'" ',
                            // 'dur="30s" begin="animation.begin" ',
                        //     'begin="animation.begin" ',
                        //     'repeatCount="indefinite" ',
                        // '/>',
                    '</use>'
                    // '</path>',
                '</g>'
            ));
        }

        return string(checksBytes);
    }

    function generateSVG(
        IChecks.Check memory check, uint8[8] memory DIVISORS, IChecks.Data storage checks
    ) public view returns (bytes memory) {
        // Colors
        (string[] memory colors_, uint256[] memory colorIndexes_) = colors(check, DIVISORS, checks);

        // Positioning
        CheckRenderData memory data;
        data.colors = colors_;
        data.colorIndexes = colorIndexes_;
        data.checksCount = check.checks;
        data.seed = check.seed;
        data.scale = data.checksCount > 20 ? '1' : '2.8';
        data.spaceX = data.checksCount == 80 ? 36 : 72;
        data.spaceY = data.checksCount > 20 ? 36 : 72;
        data.perRow = perRow(data.checksCount);
        data.rowX = rowX(data.checksCount);
        data.rowY = rowY(data.checksCount);
        data.indent = data.checksCount == 40;

        // Animation
        // TODO: Check if we can/should limit the color space?
        // data.duration = Utils.uint2str(data.checksCount*3);

        console.log('hi');
        console.log(data.checksCount);
        console.log(data.seed);
        console.log(data.scale);
        console.log(data.spaceX);
        console.log(data.spaceY);
        console.log(data.perRow);
        console.log(data.rowX);
        console.log(data.rowY);
        console.log(data.indent);
        console.log('hi');


        return abi.encodePacked(
            '<svg ',
                'viewBox="0 0 680 680" ',
                'fill="none" xmlns="http://www.w3.org/2000/svg" ',
                'style="width:100%;background:#EFEFEF;"',
            '>',
                '<defs>',
                    '<path id="check" d="',CHECKS_PATH,'"></path>',
                    '<animate id="colors" ',
                        'attributeName="fill" values="',fillAnimation(),'" ',
                        'dur="240s" begin="animation.begin" ',
                        'repeatCount="indefinite" ',
                    '/>',
                '</defs>',
                '<rect width="680" height="680" fill="#EFEFEF" />',
                '<rect x="188" y="152" width="304" height="376" fill="white"/>',
                generateChecks(data),
                '<rect width="680" height="680" fill="transparent">',
                    '<animate ',
                        'attributeName="width" ',
                        'from="680" ',
                        'to="0" ',
                        'dur="0.2s" ',
                        'begin="click" ',
                        'fill="freeze" ',
                        'id="animation"',
                    '/>',
                '</rect>',
            '</svg>'
        );
    }

    // function generateHTML(IChecks.Check memory check, string[81] memory COLORS) public pure returns (bytes memory) {
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
    //             generateSVG(check, COLORS),
    //         '</body>',
    //         '</html>'
    //     );
    // }
}
