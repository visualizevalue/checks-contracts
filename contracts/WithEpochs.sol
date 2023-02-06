//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 /////////////////////////
 //                     //
 //       M I N T       //
 //                     //
 //         ↓↓          //
 //         ↓↓          //
 //         ↓↓          //
 //                     //
 //       ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓       //
 //                     //
 /////////////////////////

@title  WithEpochs
@author VisualizeValue
@notice Powers the mint commit → reveal scheme for checks.
*/
contract WithEpochs {
    uint256 internal epochIndex = 0;

    mapping(uint256 => Epoch) internal epochs;

    function currentEpoch () public view returns (uint256, Epoch memory) {
        return (epochIndex, epochs[epochIndex]);
    }

    function nextEpoch() public returns (uint256, Epoch memory) {
        uint256 newEpochIndex = epochIndex + 1;
        Epoch storage newEpoch = epochs[newEpochIndex];

        if (
            // Initialize the next epoch or
            newEpoch.blockNumber == 0 ||
            // Reinitialize it if it's not been resolved in time.
            newEpoch.blockNumber < block.number - 256
        ) {
            // Set the minimum wait time until resolve.
            newEpoch.blockNumber = uint64(block.number + 5);
        }
        // Advance the epoch if we've waited long enough.
        else if (newEpoch.blockNumber < block.number) {
            // Set the source of randomness for our last epoch
            newEpoch.randomness = uint128(uint256(blockhash(newEpoch.blockNumber)));

            epochIndex = newEpochIndex;
        }

        return (newEpochIndex, newEpoch);
    }
}

struct Epoch {
    uint128 randomness;
    uint64 blockNumber;
}
