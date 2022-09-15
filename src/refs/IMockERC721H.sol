// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @author Philippe Dumonet <philippe@dumo.net>
interface IMockERC721H is IERC721 {
    function mint(address, uint256) external virtual;

    function safeMint(address, uint256) external virtual;

    function burn(uint256) external virtual;

    function totalSupply() external view virtual returns (uint256);
}
