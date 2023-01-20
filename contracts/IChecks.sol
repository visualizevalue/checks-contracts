// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IChecks {

    struct Check {
        uint32 seed; // Seed for the color randomisation
        uint16[7] composite; // The tokenIds that were merged into this one
        uint8 checks; // How many checks are in this
        uint8 divisorIndex; // Easy access to next / previous divisor
    }

    struct Checks {
        mapping(uint256 => Check) all;
    }

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
