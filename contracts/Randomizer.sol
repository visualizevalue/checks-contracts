//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 /////////////////////////////////
 //                             //
 //                             //
 //                             //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //                             //
 //                             //
 //                             //
 /////////////////////////////////

@title  Randomizer
@author VisualizeValue
@notice The randomizer/seed storage for checks.
*/


struct Epoch {
    //20 bytes - 160 bits
    address actor;

    //16 bytes - 128 bts
    uint256 seed;

    //32 bytes - 256 bits
    uint256 randomness;

    //8 bytes - 64 bites
    uint64 blockNumber;

    //1 bytes - 8 bites;
    bool solved;

    //Total - 44 bytes - 352 bits
    //2 slots per epoch.
}


contract Randomizer {

    uint256 internal prime = 855830179222279045468627594463;
    uint256 internal iterations = 1000;

    uint256 internal currentEpoch = 0;

    mapping(uint256 => Epoch) internal epochs;

    function advanceEpoch() public {

        //Some requirement for timing.
        //Must be a minimum of 5 blocks per epoch.
        if(currentEpoch > 0) {
            require(epochs[currentEpoch - 1].solved);
            require(epochs[currentEpoch - 1].blockNumber <= block.number -5);
        }


        //Store epoch with seed as blockhash of last block.
        epochs[currentEpoch] = Epoch(
            msg.sender,
            uint256(keccak256(abi.encodePacked(msg.sender, currentEpoch, blockhash(block.number - 1)))),
            block.number,
            0,
            false
        );
    }
}
