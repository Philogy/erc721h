// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";
import {IMockERC721H} from "../src/refs/IMockERC721H.sol";
import {ERC721Azuki} from "../src/refs/ERC721Azuki.sol";
import {ERC721OZ} from "../src/refs/ERC721OZ.sol";

/// @author Philippe Dumonet <philippe@dumo.net>
contract CompareERC721Test is Test {
    IMockERC721H internal erc721h;
    ERC721Azuki internal erc721a;
    ERC721OZ internal erc721oz;

    address constant USER1 = address(bytes20(keccak256("user1")));
    address constant USER2 = address(bytes20(keccak256("user2")));
    address constant USER3 = address(bytes20(keccak256("user3")));

    function setUp() public {
        erc721h = IMockERC721H(HuffDeployer.config().deploy("MockERC721H"));
        erc721h.mint(USER1, 20);
        vm.prank(USER1);
        erc721h.transferFrom(USER1, USER1, 1);

        erc721a = new ERC721Azuki();
        erc721a.mint(USER1, 20);
        vm.prank(USER1);
        erc721a.transferFrom(USER1, USER1, 1);

        erc721oz = new ERC721OZ();
        erc721oz.mint(USER1, 20);
        vm.prank(USER1);
        erc721oz.transferFrom(USER1, USER1, 1);
    }

    function testMint50OZ() public {
        erc721oz.mint(USER1, 50);
    }

    function testMint50Azuki() public {
        erc721a.mint(USER1, 50);
    }

    function testMint50Huff() public {
        erc721h.mint(USER1, 50);
    }

    function testMint200OZ() public {
        erc721oz.mint(USER1, 200);
    }

    function testMint200Azuki() public {
        erc721a.mint(USER1, 200);
    }

    function testMint200Huff() public {
        erc721h.mint(USER1, 200);
    }

    function testSimpleTransfer20InOZ() public {
        vm.prank(USER1);
        erc721oz.transferFrom(USER1, USER2, 20);
    }

    function testSimpleTransfer20InAzuki() public {
        vm.prank(USER1);
        erc721a.transferFrom(USER1, USER2, 20);
    }

    function testSimpleTransfer20InHuff() public {
        vm.prank(USER1);
        erc721h.transferFrom(USER1, USER2, 20);
    }

    function testSimpleTransfer1InOZ() public {
        vm.prank(USER1);
        erc721oz.transferFrom(USER1, USER2, 2);
    }

    function testSimpleTransfer1InAzuki() public {
        vm.prank(USER1);
        erc721a.transferFrom(USER1, USER2, 2);
    }

    function testSimpleTransfer1InHuff() public {
        vm.prank(USER1);
        erc721h.transferFrom(USER1, USER2, 2);
    }

    function testSimpleTransferOZ() public {
        vm.prank(USER1);
        erc721oz.transferFrom(USER1, USER2, 1);
    }

    function testSimpleTransferAzuki() public {
        vm.prank(USER1);
        erc721a.transferFrom(USER1, USER2, 1);
    }

    function testSimpleTransferHuff() public {
        vm.prank(USER1);
        erc721h.transferFrom(USER1, USER2, 1);
    }

    function testSimpleBurnOZ() public {
        erc721oz.burn(1);
    }

    function testSimpleBurnAzuki() public {
        erc721a.burn(1);
    }

    function testSimpleBurnHuff() public {
        erc721h.burn(1);
    }

    function testSimpleBurn1InOZ() public {
        erc721oz.burn(2);
    }

    function testSimpleBurn1InAzuki() public {
        erc721a.burn(2);
    }

    function testSimpleBurn1InHuff() public {
        erc721h.burn(2);
    }
}
