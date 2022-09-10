// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @author Philippe Dumonet <philippe@dumo.net>
interface IERC721H is IERC721 {
    error OwnerQueryForNonexistentToken();
    error MintZeroQuantity();
    error MintToZeroAddress();
    error TransferToNonERC721ReceiverImplementer();
    error AttemptedSafeMintReentrancy();
}
