//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SlothVDF.sol";
import "hardhat/console.sol";
/**

 /////////////////////////////////
 //                             //
 //                             //
 //                             //
 //      ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓     //
 //      ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓     //
 //      ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓     //
 //      ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓     //
 //      ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓     //
 //      ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓     //
 //      ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓     //
 //      ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓     //
 //      ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓     //
 //      ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓     //
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

    uint256 public prime = 855830179222279045468627594463;
    uint256 public iterations = 1000;

    uint256 public currentEpoch = 0;

    mapping(uint256 => Epoch) public epochs;

    function advanceEpoch() public {

        //Some requirement for timing.
        //Must be a minimum of 5 blocks per epoch.
        if(currentEpoch > 0) {
            require(epochs[currentEpoch - 1].solved, "Previous epoch has not been solved!");
            require(epochs[currentEpoch - 1].blockNumber <= block.number -5, "5 block haven't passed since the last epoch!");
        }

        //Store epoch with seed as blockhash of last block.
        epochs[currentEpoch] = Epoch(
            msg.sender,
            uint256(keccak256(abi.encodePacked(msg.sender, currentEpoch, blockhash(block.number - 1)))),
            0,
            0,
            false
        );

        console.log(epochs[currentEpoch].seed);

    }

    function solveEpoch(uint256 proof, uint256 epochToSolve) public {
        //Ensure epoch exists and has not been solved.
        require(epochs[epochToSolve].seed > 0 && epochs[epochToSolve].solved == false, "Epoch doesn't exist, or is already solved!");

        //Validate proof.
        require(SlothVDF.verify(proof, epochs[epochToSolve].seed, prime, iterations), "Invalid proof");

        //Set randomness.
        epochs[epochToSolve].randomness = proof;
    }

    function getRandomnessForEpoch(uint256 epochToRequest) public view returns(uint256) {
        return epochs[epochToRequest].randomness;
    }

    function getSeedForEpoch(uint256 epochToRequest) public view returns(uint256) {
        return epochs[epochToRequest].seed;
    }

}
