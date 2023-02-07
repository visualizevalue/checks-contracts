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

struct Epoch {
    uint128 randomness;
    uint64 revealBlock;
    bool commited;
    bool revealed;
}


abstract contract WithEpochs {
    uint256 public epochIndex = 1;

    mapping(uint256 => Epoch) public epochs;

    function initializeOrResolveEpoch() public {
        Epoch storage currentEpoch = epochs[epochIndex];

        if (
            // If epoch has not been commited,
            currentEpoch.commited == false ||
            // Or the reveal commitment timed out.
            (currentEpoch.revealed == false && currentEpoch.revealBlock < block.number - 256)
        ) {
            // This means the epoch has not been commited, OR the epoch was commited but has expired.
            initializeEpoch();
        } else if (block.number > currentEpoch.revealBlock) {
            // Epoch has been commited and is within range to be revealed.
            resolveEpoch();
            initializeEpoch();
        }
    }

    function initializeEpoch() internal {
        Epoch storage currentEpoch = epochs[epochIndex];

        // Set commited to true, and record the reveal block.
        currentEpoch.revealBlock = uint64(block.number + 5);
        currentEpoch.commited = true;
    }

    function resolveEpoch() internal {
        Epoch storage currentEpoch = epochs[epochIndex];

        // Set its randomness to the target block
        currentEpoch.randomness = uint128(uint256(blockhash(currentEpoch.revealBlock)) % (2 ** 128 - 1));
        currentEpoch.revealed = true;

        epochIndex++;
    }
}
