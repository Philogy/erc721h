// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @author Philippe Dumonet <philippe@dumo.net>
interface IMockERC721H is IERC721 {
    function mint(address, uint256) external;

    function safeMint(address, uint256) external;

    function burn(uint256) external;

    function totalSupply() external view returns (uint256);

    function tokenURI(uint256) external view returns (string memory);

    function shuffle(
        bytes32,
        uint256,
        uint256,
        uint256
    ) external view returns (uint256);
}
