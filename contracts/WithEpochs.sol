//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**

 /////////////////////////
 //                     //
 //                     //
 //     C O M M I T     //
 //                     //
 //         ↓↓          //
 //         ↓↓          //
 //         ↓↓          //
 //                     //
 //     R E V E A L     //
 //                     //
 //                     //
 /////////////////////////

@title  WithEpochs
@author mousedev.eth 🐭, jalil.eth
@notice Onchain sources of randomness via future commitments.
*/
abstract contract WithEpochs {
    uint256 internal epochIndex = 0;

    mapping(uint256 => Epoch) internal epochs;

    function currentEpoch () public view returns (uint256, Epoch memory) {
        return (epochIndex, epochs[epochIndex]);
    }

    function nextEpoch() public returns (uint256, Epoch memory) {
        uint256 newEpochIndex = epochIndex + 1;
        Epoch storage newEpoch = epochs[newEpochIndex];

        if (
            // Initialize the next epoch
            newEpoch.blockNumber == 0 ||
            // Or reinitialize it if it's not been resolved in time.
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

            return nextEpoch();
        }

        return (newEpochIndex, newEpoch);
    }
}

struct Epoch {
    uint128 randomness;
    uint64 blockNumber;
}
