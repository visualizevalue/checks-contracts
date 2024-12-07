// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IChecks {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function compositeMany(uint256[] calldata tokenIds, uint256[] calldata burnIds) external;
}

/// @notice Composite single checks in one transaction.
/// @author Visualize Value
contract Compositor {

    /// @dev Reference to Checks Originals
    IChecks immutable CHECKS = IChecks(0x036721e5A769Cc48B3189EFbb9ccE4471E8A48B1);

    /// @dev Thrown if trying to composite an invalid number of tokens
    error InvalidTokenCount();

    /// @dev Thrown when trying to composite unauthorized checks.
    error InvalidTokenOwnership();

    /// @notice Composite multiple checks to one remaining.
    /// @param tokenIds The token IDs to composite. The first one will be the keeper.
    function composite(uint256[] calldata tokenIds) external {
        // Make sure we have a compositable number of tokens.
        _checkAmount(tokenIds.length);

        // Make sure all tokens are owned by the current user.
        _checkOwnership(tokenIds);

        // Perform the composite Recursively.
        _composite(tokenIds);
    }

    /// @dev Recursively composite until only the first token is left.
    function _composite(uint256[] memory tokenIds) internal {
        (uint256[] memory first, uint256[] memory second) = _split(tokenIds);
        CHECKS.compositeMany(first, second);

        if (first.length >= 2) _composite(first);
    }

    /// @dev Split the given array in two. Assumes arrays are always of even length.
    function _split(uint256[] memory arr) internal pure returns (uint256[] memory, uint256[] memory) {
        uint256 mid = arr.length / 2;

        uint256[] memory first = new uint256[](mid);
        uint256[] memory second = new uint256[](mid);

        for (uint256 i = 0; i < mid; i++) {
            first[i] = arr[i];
            second[i] = arr[mid + i];
        }

        return (first, second);
    }

    /// @dev Check if n is greater than 0, a power of 2, and <= 64.
    function _checkAmount(uint256 n) internal pure {
        if (n >= 2 && (n & (n - 1)) == 0 && n <= 64) return;

        revert InvalidTokenCount();
    }

    /// @dev Check token ownership. Even though the checks contract checks ownership,
    ///      we have to ensure ownership to prevent unintended cross-user composites.
    function _checkOwnership(uint256[] calldata tokenIds) internal {
        address expected = msg.sender;
        uint256 amount = tokenIds.length;

        for (uint256 idx = 0; idx < amount; idx++) {
            if (CHECKS.ownerOf(tokenIds[idx]) != expected) revert InvalidTokenOwnership();
        }
    }
}




