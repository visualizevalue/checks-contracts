//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Utils {
    /// @dev Create a pseudo random number
    function seed(uint256 nonce) public view returns (uint256) {
        return uint256(
            keccak256(abi.encodePacked(msg.sender, block.coinbase, nonce))
        );
    }

    /// @dev Pseudorandom number based on input max bound
    function random(uint256 input, uint256 max) public pure returns (uint256) {
        return max - (uint256(keccak256(abi.encodePacked(input))) % max);
    }

    /// @dev Pseudorandom number based on input within bounds
    function random(uint256 input, uint256 min, uint256 max) public pure returns (uint256) {
        uint256 randRange = max - min;
        return max - (uint256(keccak256(abi.encodePacked(input))) % randRange) - 1;
    }

    /// @dev Convert an integer to a string
    function uint2str(uint256 _i) public pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
