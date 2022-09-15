// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @author Philippe Dumonet <philippe@dumo.net>
contract ERC721OZ is ERC721 {
    uint256 public constant START_TOKEN_ID = 1;

    uint256 public totalSupply;

    constructor() ERC721("", "") {}

    function mint(address _to, uint256 _quantity) external {
        unchecked {
            uint256 initialTokenId = totalSupply + START_TOKEN_ID;
            for (uint256 i; i < _quantity; i++) {
                _mint(_to, initialTokenId + i);
            }
            totalSupply += _quantity;
        }
    }

    function safeMint(address _to, uint256 _quantity) external {
        unchecked {
            uint256 initialTokenId = totalSupply + START_TOKEN_ID;
            for (uint256 i; i < _quantity; i++) {
                _safeMint(_to, initialTokenId + i);
            }
            totalSupply += _quantity;
        }
    }

    function burn(uint256 _tokenId) external {
        _burn(_tokenId);
        unchecked {
            totalSupply--;
        }
    }
}
