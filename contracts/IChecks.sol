// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IChecks {

    struct StoredCheck {
        uint32 seed;          // The seed is based the mint and enables pseudo-randomisation
        uint16[6] composite; // The tokenIds that were composited into this one
        uint8[6] colorBand;
        uint8[6] gradient;
        uint8 divisorIndex; // Easy access to next / previous divisor
        uint8 speed;    // Animation speed
    }

    struct Check {
        uint32 seed;          // The seed is based the mint and enables pseudo-randomisation
        uint16[6] composite; // The tokenIds that were composited into this one
        uint8 divisorIndex; // Easy access to next / previous divisor
        uint8 checksCount; // How many checks this token has
        uint8[6] colorBand;  // 100%, 50%, 25%, 12.5%, 6.25%, 5%, 1.25%
        uint8[6] gradient;  // Linearly through the colorBand [1, 2, 3]
        uint8 speed;    // Animation speed
    }

    struct Checks {
        uint32 minted;
        uint32 burned;
        mapping(uint256 => StoredCheck) all;
    }

    event Sacrifice(
        uint256 indexed burnedId,
        uint256 indexed tokenId
    );

    event Composite(
        uint256 indexed tokenId,
        uint256 indexed burnedId,
        uint8 indexed checks
    );

    event Infinity(
        uint256 indexed tokenId,
        uint256[] indexed burnedIds
    );

}
