// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";

/// @author Philippe Dumonet <philippe@dumo.net>
contract ERC721Azuki is ERC721A {
    constructor() ERC721A("", "") {}

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    function mint(address _to, uint256 _quantity) external {
        _mint(_to, _quantity);
    }

    function safeMint(address _to, uint256 _quantity) external {
        _safeMint(_to, _quantity);
    }

    function burn(uint256 _tokenId) external {
        _burn(_tokenId);
    }
}
