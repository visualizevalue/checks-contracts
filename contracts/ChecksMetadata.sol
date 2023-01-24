//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";
import "./IChecks.sol";
import "./ChecksArt.sol";

library ChecksMetadata {

    function tokenURI(
        uint256 tokenId, IChecks.Checks storage checks
    ) public view returns (string memory) {
        // IChecks.Check memory check = ChecksArt.getCheck(tokenId, checks);

        bytes memory svg = ChecksArt.generateSVG(tokenId, checks);
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
