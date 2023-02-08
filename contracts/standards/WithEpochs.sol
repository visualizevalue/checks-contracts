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
@author mousedev.eth 🐭
@notice Onchain sources of randomness via future commitments.
*/

struct Epoch {
    uint128 randomness;
    uint64 revealBlock;
    bool committed;
    bool revealed;
}

contract WithEpochs {
    uint256 public epochIndex = 1;

    mapping(uint256 => Epoch) public epochs;

    function resolveEpochIfNeeded() public {
        Epoch storage currentEpoch = epochs[epochIndex];

        if (
            // If epoch has not been committed
            currentEpoch.committed == false ||
            // If epoch has not been revealed, but the block is too far away (256 block)
            (currentEpoch.revealed == false && currentEpoch.revealBlock < block.number - 256)
        ) {
            // This means the epoch has not been committed, OR the epoch was committed but has expired.

            // Set committed to true, and record the reveal block
            currentEpoch.revealBlock = uint64(block.number + 50);
            currentEpoch.committed = true;

        } else if (block.number > currentEpoch.revealBlock) {
            // Epoch has been committed and is within range to be revealed.
            // Set its randomness to the target block
            currentEpoch.randomness = uint128(uint256(keccak256(abi.encodePacked(blockhash(currentEpoch.revealBlock), block.difficulty))) % (2 ** 128 - 1));
            currentEpoch.revealed = true;

            epochIndex++;

            return resolveEpochIfNeeded();
        }
    }
}
