// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IChecks {

    struct StoredCheck {
        uint16[6] composites;  // The tokenIds that were composited into this one
        // TODO: - only need to store 5...
        uint8[6] colorBands;  // The length of the used color band in percent
        uint8[6] gradients;  // Gradient settings for each generation
        uint8 divisorIndex; // Easy access to next / previous divisor
        // uint8 animation;   // Animation seed
        // uint32 seed;      // The seed enables pseudo-randomisation
        uint32 epoch;
        uint24 day;      // The days since token was created
    }

    struct Check {
        StoredCheck stored;
        uint16 composite;       // The parent tokenId that was composited into this one
        bool isRevealed;        // Whether it is revealed
        bool isRoot;           // Whether it has 80 checks
        bool hasManyChecks;    // Quick access for whether the check has many checks
        uint8 checksCount;    // How many checks this token has
        uint32 seed;         // The seed enables pseudo-randomisation
        uint8 colorBand;    // 100%, 50%, 25%, 12.5%, 6.25%, 5%, 1.25%
        uint8 gradient;    // Linearly through the colorBand [1, 2, 3]
        uint8 direction;  // Animation direction
        uint8 speed;     // Animation speed
    }

    struct Epoch {
        uint128 randomness;
        uint64 blockNumber;
    }

    struct Checks {
        uint32 day0;
        uint32 minted;
        uint32 burned;
        uint256 epoch;
        mapping(uint256 => Epoch) epochs;
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

    error NotAllowed();
    error InvalidTokenCount();
    error BlackCheck__InvalidCheck();

}
