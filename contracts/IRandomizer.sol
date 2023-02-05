// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IChecksEdition {
    
    function advanceEpoch() external;
    function solveEpoch(uint256 proof, uint256 epochToSolve) external;

    function getRandomnessForEpoch(uint256 epochToRequest) external view returns(uint256);
}
