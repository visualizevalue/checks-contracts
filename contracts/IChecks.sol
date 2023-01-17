// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IChecks {

    struct Check {
        uint8 checks; // How many checks are in this
        uint8 divisorIndex; // Easy access to next / previous divisor
        uint16[7] composite; // The tokenIds that were merged into this one
        uint32 seed; // Seed for the color randomisation
    }

    struct Data {
        mapping(uint256 => Check) all;
    }

    event Composite(
        uint256 indexed tokenId,
        uint256 indexed burnedId,
        uint8 indexed checks
    );

    event Zero(
        uint256 indexed tokenId,
        uint256[] indexed burnedIds
    );

}
