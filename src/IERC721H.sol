// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @author Philippe Dumonet <philippe@dumo.net>
interface IERC721H is IERC721 {
    error OwnerQueryForNonexistentToken();
    error MintZeroQuantity();
    error MintToZeroAddress();
    error TransferToNonERC721ReceiverImplementer();
    error AttemptedSafeMintReentrancy();
    error ApprovalQueryForNonexistentToken();
    error ApprovalCallerNotOwnerNorApproved();
    error TransferFromIncorrectOwner();
    error TransferCallerNotOwnerNorApproved();
    error TransferToZeroAddress();
}
