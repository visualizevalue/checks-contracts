// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract ZoraEdition is ERC721Burnable {
    constructor() ERC721("Checks", "Check") {
        //
    }

    function mintArbitrary(uint256 _tokenId) public {
        _mint(msg.sender, _tokenId);
    }

    function mintAmount(uint256 amount) public {
        for (uint i = 0; i < amount; i++) {
            _mint(msg.sender, i + 1);
        }
    }

    /// @dev Error when burning unapproved tokens.
    error TransferCallerNotOwnerNorApproved();
}
