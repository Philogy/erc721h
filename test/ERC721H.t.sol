// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";

abstract contract MockERC721H is ERC721 {
    function mint(address, uint256) external virtual;

    function totalSupply() external view virtual returns (uint256);
}

contract ERC721HTest is Test {
    address constant USER1 = address(uint160(1000));
    address constant USER2 = address(uint160(2000));
    address constant USER3 = address(uint160(3000));
    MockERC721H internal token;

    event Transfer(address indexed, address indexed, uint256 indexed);
    event Approval(address indexed, address indexed, uint256 indexed);
    event ApprovalForAll(address indexed, address indexed, bool);

    function setUp() public {
        token = MockERC721H(HuffDeployer.config().deploy("MockERC721H"));
        vm.label(address(token), "Token");
        vm.label(USER1, "user1");
        vm.label(USER2, "user2");
        vm.label(USER3, "user3");
    }

    function testInitialState() public {
        assertEq(token.totalSupply(), 0);
    }

    function testDoesNotAcceptCallValue() public {
        vm.deal(msg.sender, 1 ether);
        vm.expectRevert();
        address(token).call{value: 1 wei}(
            abi.encodeCall(token.totalSupply, ())
        );
        vm.expectRevert();
        address(token).call{value: 1 wei}(
            abi.encodeCall(token.balanceOf, (USER1))
        );

        token.mint(USER1, 1);
        uint256 tokenId = 1;
        assertEq(token.ownerOf(tokenId), USER1);

        vm.expectRevert();
        address(token).call{value: 1 wei}(
            abi.encodeCall(token.ownerOf, (tokenId))
        );
    }

    function testMint() public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), USER2, 1);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), USER2, 2);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), USER2, 3);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), USER2, 4);

        token.mint(USER2, 4);

        assertEq(token.balanceOf(USER1), 0, "user1 bal (1)");
        assertEq(token.balanceOf(USER2), 4, "user2 bal (1)");
        assertEq(token.ownerOf(1), USER2, "user2 owns #1 (1)");
        assertEq(token.ownerOf(2), USER2, "user2 owns #2 (1)");
        assertEq(token.ownerOf(3), USER2, "user2 owns #3 (1)");
        assertEq(token.ownerOf(4), USER2, "user2 owns #4 (1)");
        assertEq(token.totalSupply(), 4, "total supply (1)");

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), USER1, 5);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), USER1, 6);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), USER1, 7);

        token.mint(USER1, 3);

        assertEq(token.balanceOf(USER1), 3, "user1 bal (2)");
        assertEq(token.ownerOf(5), USER1, "user1 owns #5 (2)");
        assertEq(token.ownerOf(6), USER1, "user1 owns #6 (2)");
        assertEq(token.ownerOf(7), USER1, "user1 owns #7 (2)");
        assertEq(token.balanceOf(USER2), 4, "user2 bal (2)");
        assertEq(token.ownerOf(1), USER2, "user2 owns #1 (2)");
        assertEq(token.ownerOf(2), USER2, "user2 owns #2 (2)");
        assertEq(token.ownerOf(3), USER2, "user2 owns #3 (2)");
        assertEq(token.ownerOf(4), USER2, "user2 owns #4 (2)");
        assertEq(token.totalSupply(), 7, "total supply (2)");
    }

    function runTestInitialState() public {
        setUp();
        testInitialState();
    }
}
