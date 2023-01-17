// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract ZoraEdition is ERC721Burnable {
    constructor() ERC721("Checks", "Check") {
        //
    }
}
