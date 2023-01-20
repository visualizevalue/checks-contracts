//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";
import "./EightyColors.sol";
import "./Utilities.sol";
import "./IChecks.sol";

import "hardhat/console.sol";

struct CheckRenderData {
    IChecks.Check check;
    uint256[] colorIndexes;
    string[] colors;
    string gridColor;
    string duration;
    string scale;
    uint32 seed;
    uint16 rowX;
    uint16 rowY;
    uint8 count;
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

    function DIVISORS() public pure returns (uint8[8] memory) {
        return [ 80, 40, 20, 10, 5, 4, 1, 0 ];
    }

    // function COLORS() public pure returns (string[80] memory) {
    //     return [
    //         '#DB395E', '#525EAA', '#977A31', '#2E668B', '#33758D', '#4068C1', '#F2A43A', '#ED7C30',
    //         '#F9DA4A', '#322F92', '#5C83CB', '#FBEA5B', '#E73E53', '#DA3321', '#9AD9FB', '#77D3DE',
    //         '#D6F4E1', '#F0A0CA', '#F2B341', '#2E4985', '#25438C', '#EB5A2A', '#DB4D58', '#5FCD8C',
    //         '#FAE663', '#8A2235', '#A4C8EE', '#81D1EC', '#D97D2E', '#F9DB49', '#85C33C', '#EA3A2D',
    //         '#5A9F3E', '#EF8C37', '#F7CA57', '#EB4429', '#A7DDF9', '#F2A93B', '#F2A840', '#DE3237',
    //         '#602263', '#EC7368', '#D5332F', '#F6CBA6', '#F09837', '#F9DA4D', '#5ABAD3', '#3E8BA3',
    //         '#C7EDF2', '#E8424E', '#B1EFC9', '#93CF98', '#2F2243', '#2D5352', '#F7DD9B', '#6A552A',
    //         '#D1DF4F', '#4D3658', '#EA5B33', '#5FC9BF', '#7A2520', '#B82C36', '#F2A93C', '#4291A8',
    //         '#F4BDBE', '#FAE272', '#EF8933', '#3B2F39', '#ABDD45', '#4AA392', '#C23532', '#F6CB45',
    //         '#6D2F22', '#535687', '#EE837D', '#E0C963', '#9DEFBF', '#60B1F4', '#EE828F', '#7A5AB4',
    //         '#FFF'
    //     ];
    // }

    /// @dev Generate indexes for the color slots of its parent (root being the COLORS themselves).
    function colorIndexes(uint8 divisorIndex, IChecks.Check memory check, IChecks.Checks storage checks)
        public view returns (uint256[] memory)
    {
        uint8[8] memory divisors = DIVISORS();
        uint256 checksCount = divisors[divisorIndex];
        uint256 possibleColorChoices = divisorIndex > 0 ? divisors[divisorIndex - 1] * 2 : 80;

        uint256[] memory indexes = new uint256[](checksCount);
        indexes[0] = Utils.random(check.seed, 0, possibleColorChoices - 1);
        for (uint i = 0; i < checksCount; i++) {
            // // TODO: check
            // if (check.gradient) {
            // }
            indexes[i] = check.gradient > 0
                ? (indexes[0] + i) % 80
                : Utils.random(check.seed + i, 0, possibleColorChoices - 1);
        }

        if (divisorIndex > 0) {
            uint8 previousDivisor = divisorIndex - 1;

            uint256[] memory parentIndexes = colorIndexes(previousDivisor, check, checks);

            IChecks.Check memory composited = checks.all[check.composite[previousDivisor]];
            uint256[] memory compositedIndexes = colorIndexes(previousDivisor, composited, checks);

            // Replace random indices with parent / root color indices
            uint8 count = divisors[previousDivisor];
            for (uint i = 0; i < divisors[divisorIndex]; i++) {
                uint256 branchIndex = indexes[i] % count;
                indexes[i] = indexes[i] < count
                    ? parentIndexes[branchIndex]
                    : compositedIndexes[branchIndex];
            }
        }

        return indexes;
    }

    function colors(
        IChecks.Check memory check, IChecks.Checks storage checks
    ) public view returns (string[] memory, uint256[] memory) {
        // A fully composited check has no color.
        if (check.checks == 0) {
            string[] memory zeroColors;
            zeroColors[0] = '#FFF';
            return (zeroColors, new uint256[](999));
        }

        // Fetch the indices on the original color mapping.
        uint256[] memory indexes = colorIndexes(check.divisorIndex, check, checks);

        // Map over to get the colors.
        string[] memory checkColors = new string[](check.checks);
        string[80] memory allColors = EightyColors.COLORS();

        // Always set the first color
        checkColors[0] = allColors[indexes[0]];
        for (uint i = 1; i < indexes.length; i++) {
            checkColors[i] = check.gradient > 0
                ? allColors[(indexes[0] + i * check.gradient) % 80]
                : allColors[indexes[i]];
        }

        return (checkColors, indexes);
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

    function fillAnimation(CheckRenderData memory data, uint256 offset, string[80] memory allColors) public pure returns (
        string memory duration, string memory animation
    ) {
        uint8 count = 20;
        uint8 gradient = data.check.gradient;

        bytes memory values;
        for (uint i = offset; i < offset + 80; i+=4) {
            values = abi.encodePacked(values, '#', allColors[i % 80], ';');
        }

        // Add initial color as last one for smooth animations
        values = abi.encodePacked(values, '#', allColors[offset]);

        return (Utils.uint2str(count * 1), string(values));
    }

    function generateChecks(CheckRenderData memory data) public pure returns (string memory) {
        bytes memory checksBytes;
        string[80] memory allColors = EightyColors.COLORS();

        for (uint8 i = 0; i < data.count; i++) {
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

            // Animation
            (string memory duration, string memory animation) = fillAnimation(data, data.colorIndexes[i], allColors);

            checksBytes = abi.encodePacked(checksBytes, abi.encodePacked(
                '<g transform="translate(', translateX, ', ', translateY, ')">',
                    '<use href="#check" transform="scale(',data.scale,')" fill="#',data.colors[i],'">',
                    // '<use href="#square" transform="translate(-8, -7) scale(',data.count > 20 ? '1' : '2',')" fill="#',data.colors[i],'">',
                        '<animate ',
                            'attributeName="fill" values="',animation,'" ',
                            'dur="',duration,'s" begin="animation.begin" ',
                            'repeatCount="indefinite" ',
                        '/>',
                    '</use>'
                '</g>'
            ));
        }

        return string(checksBytes);
    }

    function collectRenderData(
        IChecks.Check memory check, IChecks.Checks storage checks
    ) public view returns (CheckRenderData memory data) {
        // Base config
        data.check = check;
        data.count = check.checks;
        data.seed = check.seed;

        // Colors
        (string[] memory colors_, uint256[] memory colorIndexes_) = colors(check, checks);
        data.colorIndexes = colorIndexes_;
        data.colors = colors_;
        data.gridColor = data.count > 0 ? '#191919' : '#F2F2F2';

        // Positioning
        data.scale = data.count > 20 ? '1' : data.count > 1 ? '2' : '3';
        data.spaceX = data.count == 80 ? 36 : 72;
        data.spaceY = data.count > 20 ? 36 : 72;
        data.perRow = perRow(data.count);
        data.indent = data.count == 40;
        data.rowX = rowX(data.count);
        data.rowY = rowY(data.count);
    }

    function generateGridRow() public pure returns (bytes memory) {
        bytes memory row;
        for (uint i = 0; i < 8; i++) {
            row = abi.encodePacked(
                row,
                '<use href="#square" x="',Utils.uint2str(196 + i*36),'" y="160"/>'
            );
        }
        return row;
    }

    function generateGrid() public pure returns (bytes memory) {
        bytes memory grid;
        for (uint i = 0; i < 10; i++) {
            grid = abi.encodePacked(
                grid,
                '<use href="#row" y="', Utils.uint2str(i*36), '"/>'
            );
        }

        return abi.encodePacked('<g id="grid" x="196" y="160">', grid, '</g>');
    }

    function generateSVG(
        IChecks.Check memory check, IChecks.Checks storage checks
    ) public view returns (bytes memory) {
        CheckRenderData memory data = collectRenderData(check, checks);

        return abi.encodePacked(
            '<svg ',
                'viewBox="0 0 680 680" ',
                'fill="none" xmlns="http://www.w3.org/2000/svg" ',
                'style="width:100%;background:black;"',
            '>',
                '<defs>',
                    '<path id="check" d="',CHECKS_PATH,'"></path>',
                    '<rect id="square" width="36" height="36" stroke="',data.gridColor,'"></rect>',
                    '<g id="row">', generateGridRow(),'</g>'
                    // '<line id="hl" x1="196" x2="484" stroke="',data.gridColor,'"/>',
                    // '<line id="vl" y1="160" y2="520" stroke="',data.gridColor,'"/>',
                '</defs>',
                '<rect width="680" height="680" fill="black"/>',
                '<rect x="188" y="152" width="304" height="376" fill="#111111"/>',
                generateGrid(),
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

    function tokenURI(uint256 tokenId, IChecks.Check memory check, IChecks.Checks storage checks) public view returns (string memory) {
        bytes memory svg = generateSVG(check, checks);
        bytes memory metadata = abi.encodePacked(
            '{',
                '"name": "Checks ', tokenId, '",',
                '"description": "This artwork may or may not be notable",',
                '"image": ',
                    '"data:image/svg+xml;base64,',
                    Base64.encode(svg),
                    '"',
                '"animation_url": ',
                    '"data:text/html;base64,',
                    Base64.encode(generateHTML(svg)),
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

    function generateHTML(bytes memory svg) public pure returns (bytes memory) {
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
                svg,
            '</body>',
            '</html>'
        );
    }
}
