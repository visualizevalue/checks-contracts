//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
    string public constant CHECKS_PATH = 'M21.36 9.886A3.933 3.933 0 0 0 18 8c-1.423 0-2.67.755-3.36 1.887a3.935 3.935 0 0 0-4.753 4.753A3.933 3.933 0 0 0 8 18c0 1.423.755 2.669 1.886 3.36a3.935 3.935 0 0 0 4.753 4.753 3.933 3.933 0 0 0 4.863 1.59 3.953 3.953 0 0 0 1.858-1.589 3.935 3.935 0 0 0 4.753-4.754A3.933 3.933 0 0 0 28 18a3.933 3.933 0 0 0-1.887-3.36 3.934 3.934 0 0 0-1.042-3.711 3.934 3.934 0 0 0-3.71-1.043Zm-3.958 11.713 4.562-6.844c.566-.846-.751-1.724-1.316-.878l-4.026 6.043-1.371-1.368c-.717-.722-1.836.396-1.116 1.116l2.17 2.15a.788.788 0 0 0 1.097-.22Z';

    function DIVISORS() public pure returns (uint8[8] memory) {
        return [ 80, 40, 20, 10, 5, 4, 1, 0 ];
    }

    function getCheck(
        uint256 tokenId, IChecks.Checks storage checks
    ) public view returns (IChecks.Check memory check) {
        IChecks.StoredCheck memory stored = checks.all[tokenId];

        check.seed = stored.seed;
        check.divisorIndex = stored.divisorIndex;
        check.checksCount = DIVISORS()[stored.divisorIndex];
        check.composite = stored.composite;
        check.colorBand = stored.colorBand;
        check.gradient = stored.gradient;
        check.speed = stored.speed;

        return check;
    }

    /// @dev Generate indexes for the color slots of its parent (root being the COLORS themselves).
    function colorIndexes(
        uint8 divisorIndex, IChecks.Check memory check, IChecks.Checks storage checks
    ) public view returns (uint256[] memory)
    {
        uint8[8] memory divisors = DIVISORS();
        uint256 checksCount = divisors[divisorIndex];

        // If we're a composited check, we choose colors only based on
        // the slots available in our parents. Otherwise,
        // we choose based on our available spectrum.
        uint256 possibleColorChoices = divisorIndex > 0
            ? divisors[divisorIndex - 1] * 2
            : 80;

        // We initialize our index and select the first color
        uint256[] memory indexes = new uint256[](checksCount);
        indexes[0] = Utils.random(check.seed, 0, possibleColorChoices);

        // Based on the color band, and whether it's a gradient check,
        // we select all other colors.
        if (divisorIndex < 6) {
            uint8 gradient = check.gradient[divisorIndex];
            uint8 colorBand = check.colorBand[divisorIndex];

            for (uint i = 1; i < checksCount; i++) {
                indexes[i] = gradient > 0 && gradient < 6
                    ? (indexes[0] + ((i * gradient) * colorBand / checksCount) % colorBand) % 80
                    : (indexes[0] + Utils.random(check.seed + i, 0, colorBand)) % 80;
            }
        }

        if (divisorIndex > 0) {
            uint8 previousDivisor = divisorIndex - 1;

            uint256[] memory parentIndexes = colorIndexes(previousDivisor, check, checks);

            IChecks.Check memory composited = getCheck(check.composite[previousDivisor], checks);
            uint256[] memory compositedIndexes = colorIndexes(previousDivisor, composited, checks);

            // Replace random indices with parent / root color indices
            uint8 count = divisors[previousDivisor];
            for (uint i = 0; i < checksCount; i++) {
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
        if (check.divisorIndex == 7) {
            string[] memory zeroColors;
            zeroColors[0] = '#FFF';
            return (zeroColors, new uint256[](999));
        }

        // Fetch the indices on the original color mapping.
        uint256[] memory indexes = colorIndexes(check.divisorIndex, check, checks);

        // Map over to get the colors.
        string[] memory checkColors = new string[](indexes.length);
        string[80] memory allColors = EightyColors.COLORS();

        // Always set the first color
        checkColors[0] = allColors[indexes[0]];
        for (uint i = 1; i < indexes.length; i++) {
            checkColors[i] = allColors[indexes[i]];
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
        return checks <= 1
            ? 286
            : checks == 5
                ? 304
                : checks == 10
                    ? 268
                    : 196;
    }

    function rowY(uint8 checks) public pure returns (uint16) {
        return checks > 4
            ? 160
            : checks > 1
                ? 304
                : 286;
    }

    function fillAnimation(CheckRenderData memory data, uint256 offset, string[80] memory allColors) public pure returns (
        string memory duration, string memory animation
    ) {
        uint8 count = 20;

        bytes memory values;
        for (uint i = offset; i < offset + 80; i+=4) {
            values = abi.encodePacked(values, '#', allColors[i % 80], ';');
        }

        // Add initial color as last one for smooth animations
        values = abi.encodePacked(values, '#', allColors[offset]);

        return (Utils.uint2str(count * 2 / data.check.speed), string(values));
    }

    function generateChecks(CheckRenderData memory data) public pure returns (string memory) {
        bytes memory checksBytes;
        string[80] memory allColors = EightyColors.COLORS();

        uint8 checksCount = data.count;
        for (uint8 i = 0; i < checksCount; i++) {
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
                '<g transform="translate(', translateX, ', ', translateY, ') scale(', data.scale, ')">',
                    '<use href="#check" fill="#',data.colors[i],'">',
                    // '<use href="#square" transform="translate(-8, -7) scale(',checksCount > 20 ? '1' : '2',')" fill="#',data.colors[i],'">',
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
        // Carry over the check
        data.check = check;
        data.count = DIVISORS()[check.divisorIndex];

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
        uint256 tokenId, IChecks.Checks storage checks
    ) public view returns (bytes memory) {
        CheckRenderData memory data = collectRenderData(getCheck(tokenId, checks), checks);

        console.log('generateSVG');
        console.log(tokenId);

        return abi.encodePacked(
            '<svg ',
                'viewBox="0 0 680 680" ',
                'fill="none" xmlns="http://www.w3.org/2000/svg" ',
                'style="width:100%;background:black;"',
            '>',
                '<defs>',
                    '<path id="check" fill-rule="evenodd" d="',CHECKS_PATH,'"></path>',
                    '<rect id="square" width="36" height="36" stroke="',data.gridColor,'"></rect>',
                    '<g id="row">', generateGridRow(),'</g>'
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
}
