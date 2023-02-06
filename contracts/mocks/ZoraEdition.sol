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

    /// @dev Error when burning unapproved tokens.
    error TransferCallerNotOwnerNorApproved();
}
