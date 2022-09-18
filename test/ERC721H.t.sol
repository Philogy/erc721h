// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721H} from "../src/IERC721H.sol";
import {IMockERC721H} from "../src/refs/IMockERC721H.sol";

contract Set {
    mapping(uint256 => bool) public contains;
    bool public duplicatedAdded;
    uint256 public size;

    uint256 public max;
    uint256 public min;

    function add(uint256 _data) external returns (bool) {
        if (size == 0) {
            max = _data;
            min = _data;
        } else {
            if (_data > max) max = _data;
            if (_data < min) min = _data;
        }

        if (!contains[_data]) {
            size++;
            contains[_data] = true;
            return true;
        } else {
            duplicatedAdded = true;
            return false;
        }
    }
}

contract AnyDataAcceptor {
    fallback() external {}
}

contract ERC721NotAcceptor1 is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        revert("");
    }
}

contract ERC721NotAcceptor2 {}

struct Receive {
    address operator;
    address from;
    uint256 tokenId;
    bytes data;
    uint256 totalCalldataSize;
}

contract ERC721SemiAcceptor {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes32) {
        return keccak256("onERC721Received(address,address,uint256,bytes)");
    }
}

contract ERC721Acceptor is IERC721Receiver {
    Receive[] public receives;

    function totalReceives() external view returns (uint256) {
        return receives.length;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4) {
        receives.push(
            Receive({
                operator: _operator,
                from: _from,
                tokenId: _tokenId,
                data: _data,
                totalCalldataSize: msg.data.length
            })
        );
        return IERC721Receiver.onERC721Received.selector;
    }
}

contract ERC721HTest is Test {
    using Strings for uint256;

    address constant USER1 = address(bytes20(keccak256("user1")));
    address constant USER2 = address(bytes20(keccak256("user2")));
    address constant USER3 = address(bytes20(keccak256("user3")));
    address constant ATTACKER1 = address(bytes20(keccak256("attacker1")));
    IMockERC721H internal token;

    mapping(uint256 => uint256) internal rev;

    event Transfer(address indexed, address indexed, uint256 indexed);
    event Approval(address indexed, address indexed, uint256 indexed);
    event ApprovalForAll(address indexed, address indexed, bool);

    function setUp() public {
        token = IMockERC721H(HuffDeployer.config().deploy("MockERC721H"));
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

        vm.expectRevert();
        address(token).call{value: 1 wei}(
            abi.encodeCall(token.isApprovedForAll, (USER1, USER2))
        );

        vm.expectRevert();
        address(token).call{value: 1 wei}(
            abi.encodeCall(token.setApprovalForAll, (USER1, true))
        );

        vm.expectRevert();
        address(token).call{value: 1 wei}(
            abi.encodeCall(token.approve, (USER1, 1))
        );

        vm.expectRevert();
        address(token).call{value: 1 wei}(
            abi.encodeCall(token.getApproved, (1))
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

    function testSafeMintToEOA() public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), USER2, 1);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), USER2, 2);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), USER2, 3);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), USER2, 4);

        token.safeMint(USER2, 4);

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

        token.safeMint(USER1, 3);

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

    function testSafeMintRevertsNoReceive() public {
        address recipient1 = address(new ERC721NotAcceptor1());
        vm.expectRevert(
            IERC721H.TransferToNonERC721ReceiverImplementer.selector
        );
        token.safeMint(recipient1, 4);

        address recipient2 = address(new ERC721NotAcceptor2());
        vm.expectRevert(
            IERC721H.TransferToNonERC721ReceiverImplementer.selector
        );
        token.safeMint(recipient2, 3);
    }

    function testSafeMintToReceiver() public {
        ERC721Acceptor acceptor = new ERC721Acceptor();

        for (uint256 i = 1; i <= 3; i++) {
            vm.expectEmit(true, true, true, true);
            emit Transfer(address(0), address(acceptor), i);
        }

        vm.prank(USER1);
        token.safeMint(address(acceptor), 3);

        for (uint256 i = 1; i <= 3; i++) {
            assertEq(token.ownerOf(i), address(acceptor), "owner");
            (
                address operator,
                address from,
                uint256 tokenId,
                bytes memory data,
                uint256 totalCalldataSize
            ) = acceptor.receives(i - 1);
            assertEq(operator, USER1, "operator");
            assertEq(from, address(0), "from");
            assertEq(tokenId, i, "tokenId");
            assertEq(data, "", "data");
            assertEq(totalCalldataSize, 4 + 0x20 * 5);
        }
        assertEq(token.balanceOf(address(acceptor)), 3);
        assertEq(token.totalSupply(), 3);
        assertEq(acceptor.totalReceives(), 3);
    }

    function testSafeMintRevertsIncorrectReceiver() public {
        ERC721SemiAcceptor acceptor = new ERC721SemiAcceptor();
        bytes32 fullSelector = acceptor.onERC721Received(
            address(0),
            address(0),
            0,
            ""
        );
        assertEq(
            bytes4(fullSelector),
            IERC721Receiver.onERC721Received.selector
        );

        vm.expectRevert(
            IERC721H.TransferToNonERC721ReceiverImplementer.selector
        );
        token.safeMint(address(acceptor), 10);
    }

    function testApprovalForAll() public {
        assertEq(token.isApprovedForAll(USER1, USER2), false);
        assertEq(token.isApprovedForAll(USER2, USER1), false);

        vm.expectEmit(true, true, true, true);
        emit ApprovalForAll(USER1, USER2, true);

        vm.prank(USER1);
        token.setApprovalForAll(USER2, true);
        assertEq(token.isApprovedForAll(USER1, USER2), true);
        assertEq(token.isApprovedForAll(USER2, USER1), false);

        vm.expectEmit(true, true, true, true);
        emit ApprovalForAll(USER1, USER2, false);

        vm.prank(USER1);
        token.setApprovalForAll(USER2, false);
        assertEq(token.isApprovedForAll(USER1, USER2), false);
        assertEq(token.isApprovedForAll(USER2, USER1), false);

        vm.expectEmit(true, true, true, true);
        emit ApprovalForAll(USER2, USER3, false);
        vm.prank(USER2);
        token.setApprovalForAll(USER3, false);

        vm.expectRevert();
        vm.prank(USER1);
        address(token).call(
            abi.encodeWithSelector(
                token.setApprovalForAll.selector,
                USER2,
                uint256(2)
            )
        );
    }

    function testDirectTokenApproval() public {
        vm.expectRevert(IERC721H.ApprovalQueryForNonexistentToken.selector);
        token.getApproved(0);
        vm.expectRevert(IERC721H.ApprovalQueryForNonexistentToken.selector);
        token.getApproved(2);

        token.mint(USER1, 3);

        vm.expectRevert(IERC721H.ApprovalQueryForNonexistentToken.selector);
        token.getApproved(4);

        assertEq(token.getApproved(1), address(0));

        vm.expectRevert(IERC721H.ApprovalCallerNotOwnerNorApproved.selector);
        vm.prank(ATTACKER1);
        token.approve(ATTACKER1, 1);

        vm.expectEmit(true, true, true, true);
        emit Approval(USER1, USER2, 1);
        vm.prank(USER1);
        token.approve(USER2, 1);
        assertEq(token.getApproved(1), USER2);

        vm.expectRevert(IERC721H.OwnerQueryForNonexistentToken.selector);
        vm.prank(USER1);
        token.approve(USER2, 4);

        token.mint(USER2, 4);

        vm.expectEmit(true, true, true, true);
        emit Approval(USER2, USER3, 4);
        vm.prank(USER2);
        token.approve(USER3, 4);
        assertEq(token.getApproved(4), USER3);
    }

    function testOperatorForAllSetTokenApproval() public {
        token.mint(USER1, 4);

        vm.prank(USER1);
        token.setApprovalForAll(USER2, true);

        vm.prank(USER2);
        vm.expectEmit(true, true, true, true);
        emit Approval(USER1, USER3, 2);
        token.approve(USER3, 2);
        assertEq(token.getApproved(2), USER3);
    }

    function testTransferFrom() public {
        token.mint(USER1, 4);
        assertEq(token.balanceOf(USER1), 4);
        assertEq(token.balanceOf(USER2), 0);

        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit Transfer(USER1, USER2, 2);
        token.transferFrom(USER1, USER2, 2);

        assertEq(token.ownerOf(1), USER1);
        assertEq(token.ownerOf(2), USER2);
        assertEq(token.ownerOf(3), USER1);
        assertEq(token.ownerOf(4), USER1);
        assertEq(token.balanceOf(USER1), 3);
        assertEq(token.balanceOf(USER2), 1, "recipient balance");
    }

    function testTransferFromAsTokenApproved() public {
        token.mint(USER1, 4);

        vm.prank(USER1);
        token.approve(USER3, 4);

        vm.prank(USER3);
        vm.expectEmit(true, true, true, true);
        emit Transfer(USER1, USER2, 4);
        token.transferFrom(USER1, USER2, 4);

        assertEq(token.ownerOf(1), USER1);
        assertEq(token.ownerOf(2), USER1);
        assertEq(token.ownerOf(3), USER1);
        assertEq(token.ownerOf(4), USER2);
        assertEq(token.balanceOf(USER1), 3);
        assertEq(token.balanceOf(USER2), 1);
        assertEq(token.balanceOf(USER3), 0);
        assertEq(token.getApproved(4), address(0));
    }

    function testTransferFromAsOperatorApproved() public {
        token.mint(USER1, 4);

        vm.prank(USER1);
        token.setApprovalForAll(USER3, true);

        vm.expectEmit(true, true, true, true);
        emit Transfer(USER1, USER2, 4);
        vm.prank(USER3);
        token.transferFrom(USER1, USER2, 4);

        vm.expectEmit(true, true, true, true);
        emit Transfer(USER1, USER3, 2);
        vm.prank(USER3);
        token.transferFrom(USER1, USER3, 2);

        assertEq(token.ownerOf(1), USER1);
        assertEq(token.ownerOf(2), USER3);
        assertEq(token.ownerOf(3), USER1);
        assertEq(token.ownerOf(4), USER2);
        assertEq(token.balanceOf(USER1), 2);
        assertEq(token.balanceOf(USER2), 1);
        assertEq(token.balanceOf(USER3), 1);
        assertEq(token.getApproved(2), address(0));
        assertEq(token.getApproved(4), address(0));
    }

    function testTransferFromFullyTransfersOwnership() public {
        token.mint(USER1, 4);

        vm.prank(USER1);
        token.transferFrom(USER1, USER2, 1);

        vm.expectRevert(IERC721H.TransferCallerNotOwnerNorApproved.selector);
        vm.prank(USER1);
        token.transferFrom(USER2, USER1, 1);

        vm.expectRevert(IERC721H.TransferFromIncorrectOwner.selector);
        vm.prank(USER1);
        token.transferFrom(USER1, USER3, 1);

        vm.expectEmit(true, true, true, true);
        emit Transfer(USER2, USER3, 1);
        vm.prank(USER2);
        token.transferFrom(USER2, USER3, 1);
        assertEq(token.ownerOf(1), USER3);
    }

    function testCannotTransferFromToZero() public {
        token.mint(USER1, 4);

        vm.prank(USER1);
        vm.expectRevert(IERC721H.TransferToZeroAddress.selector);
        token.transferFrom(USER1, address(0), 1);
    }

    function testCannotTransferFromIncorrectOwner() public {
        token.mint(USER1, 4);

        vm.prank(USER1);
        vm.expectRevert(IERC721H.TransferFromIncorrectOwner.selector);
        token.transferFrom(USER2, USER3, 1);
    }

    function testNoDataSafeTransferFromToEOA() public {
        token.mint(USER1, 5);

        vm.expectEmit(true, true, true, true);
        emit Transfer(USER1, USER2, 5);
        vm.prank(USER1);
        token.safeTransferFrom(USER1, USER2, 5);
        assertEq(token.ownerOf(5), USER2);
        assertEq(token.balanceOf(USER2), 1);

        vm.prank(USER1);
        token.setApprovalForAll(USER3, true);

        vm.expectEmit(true, true, true, true);
        emit Transfer(USER1, USER3, 4);
        vm.prank(USER3);
        token.safeTransferFrom(USER1, USER3, 4);
        assertEq(token.ownerOf(4), USER3);
        assertEq(token.balanceOf(USER3), 1);
    }

    function testNoDataSafeTransferToReceiver() public {
        ERC721Acceptor acceptor = new ERC721Acceptor();

        token.mint(USER1, 5);

        vm.expectEmit(true, true, true, true);
        emit Transfer(USER1, address(acceptor), 5);
        vm.prank(USER1);
        token.safeTransferFrom(USER1, address(acceptor), 5);
        assertEq(token.balanceOf(USER1), 4);
        assertEq(token.balanceOf(address(acceptor)), 1);
        assertEq(token.ownerOf(5), address(acceptor));
        (
            address operator,
            address from,
            uint256 tokenId,
            bytes memory data,
            uint256 totalCalldataSize
        ) = acceptor.receives(0);
        assertEq(operator, USER1);
        assertEq(from, USER1);
        assertEq(tokenId, 5);
        assertEq(data, "");
        assertEq(totalCalldataSize, 4 + 0x20 * 5);

        vm.prank(USER1);
        token.setApprovalForAll(USER2, true);
        vm.expectEmit(true, true, true, true);
        emit Transfer(USER1, address(acceptor), 4);
        vm.prank(USER2);
        token.safeTransferFrom(USER1, address(acceptor), 4);
        assertEq(token.balanceOf(USER1), 3);
        assertEq(token.balanceOf(address(acceptor)), 2);
        assertEq(token.ownerOf(4), address(acceptor));
        (operator, from, tokenId, data, totalCalldataSize) = acceptor.receives(
            1
        );
        assertEq(operator, USER2);
        assertEq(from, USER1);
        assertEq(tokenId, 4);
        assertEq(data, "");
        assertEq(totalCalldataSize, 4 + 0x20 * 5);

        vm.prank(USER2);
        token.approve(USER3, 3);
        vm.expectEmit(true, true, true, true);
        emit Transfer(USER1, address(acceptor), 3);
        vm.prank(USER3);
        token.safeTransferFrom(USER1, address(acceptor), 3);
        assertEq(token.balanceOf(USER1), 2);
        assertEq(token.balanceOf(address(acceptor)), 3);
        assertEq(token.ownerOf(3), address(acceptor));
        (operator, from, tokenId, data, totalCalldataSize) = acceptor.receives(
            2
        );
        assertEq(operator, USER3);
        assertEq(from, USER1);
        assertEq(tokenId, 3);
        assertEq(data, "");
        assertEq(totalCalldataSize, 4 + 0x20 * 5);
    }

    function testNoDataSafeTransferFromToAnyDataAcceptorFails() public {
        token.mint(USER1, 1);

        address acceptor = address(new AnyDataAcceptor());
        vm.expectRevert(
            IERC721H.TransferToNonERC721ReceiverImplementer.selector
        );
        vm.prank(USER1);
        token.safeTransferFrom(USER1, acceptor, 1);
    }

    function testNoDataSafeTransferToNotAcceptor1Fails() public {
        token.mint(USER1, 1);

        address acceptor = address(new ERC721NotAcceptor1());
        vm.expectRevert(
            IERC721H.TransferToNonERC721ReceiverImplementer.selector
        );
        vm.prank(USER1);
        token.safeTransferFrom(USER1, acceptor, 1);
    }

    function testNoDataSafeTransferToNotAcceptor2Fails() public {
        token.mint(USER1, 1);

        address acceptor = address(new ERC721NotAcceptor2());
        vm.expectRevert(
            IERC721H.TransferToNonERC721ReceiverImplementer.selector
        );
        vm.prank(USER1);
        token.safeTransferFrom(USER1, acceptor, 1);
    }

    function testNoDataSafeTransferToSemiAcceptorFails() public {
        token.mint(USER1, 1);

        address acceptor = address(new ERC721NotAcceptor2());
        vm.expectRevert(
            IERC721H.TransferToNonERC721ReceiverImplementer.selector
        );
        vm.prank(USER1);
        token.safeTransferFrom(USER1, acceptor, 1);
    }

    function testDataSafeTransferFromToEOA() public {
        token.mint(USER1, 5);

        vm.expectEmit(true, true, true, true);
        emit Transfer(USER1, USER2, 5);
        vm.prank(USER1);
        token.safeTransferFrom(USER1, USER2, 5, "");
        assertEq(token.ownerOf(5), USER2);
        assertEq(token.balanceOf(USER2), 1);

        vm.prank(USER1);
        token.setApprovalForAll(USER3, true);

        vm.expectEmit(true, true, true, true);
        emit Transfer(USER1, USER3, 4);
        vm.prank(USER3);
        token.safeTransferFrom(USER1, USER3, 4, hex"010203");
        assertEq(token.ownerOf(4), USER3);
        assertEq(token.balanceOf(USER3), 1);
    }

    function testDataSafeTransferFromToAnyDataAcceptorFails() public {
        token.mint(USER1, 1);

        address acceptor = address(new AnyDataAcceptor());
        vm.expectRevert(
            IERC721H.TransferToNonERC721ReceiverImplementer.selector
        );
        vm.prank(USER1);
        token.safeTransferFrom(
            USER1,
            acceptor,
            1,
            "testDataSafeTransferFromToAnyDataAcceptorFails"
        );
    }

    function testDataSafeTransferToNotAcceptor1Fails() public {
        token.mint(USER1, 1);

        address acceptor = address(new ERC721NotAcceptor1());
        vm.expectRevert(
            IERC721H.TransferToNonERC721ReceiverImplementer.selector
        );
        vm.prank(USER1);
        token.safeTransferFrom(
            USER1,
            acceptor,
            1,
            "testDataSafeTransferToNotAcceptor1Fails"
        );
    }

    function testDataSafeTransferToNotAcceptor2Fails() public {
        token.mint(USER1, 1);

        address acceptor = address(new ERC721NotAcceptor2());
        vm.expectRevert(
            IERC721H.TransferToNonERC721ReceiverImplementer.selector
        );
        vm.prank(USER1);
        token.safeTransferFrom(
            USER1,
            acceptor,
            1,
            "testDataSafeTransferToNotAcceptor2Fails"
        );
    }

    function testDataSafeTransferToSemiAcceptorFails() public {
        token.mint(USER1, 1);

        address acceptor = address(new ERC721NotAcceptor2());
        vm.expectRevert(
            IERC721H.TransferToNonERC721ReceiverImplementer.selector
        );
        vm.prank(USER1);
        token.safeTransferFrom(
            USER1,
            acceptor,
            1,
            "testDataSafeTransferToSemiAcceptorFails"
        );
    }

    function testDataSafeTransferToReceiver() public {
        ERC721Acceptor acceptor = new ERC721Acceptor();

        token.mint(USER1, 5);

        bytes memory data = hex"010203";
        vm.expectEmit(true, true, true, true);
        emit Transfer(USER1, address(acceptor), 5);
        vm.prank(USER1);
        token.safeTransferFrom(USER1, address(acceptor), 5, data);
        assertEq(token.balanceOf(USER1), 4);
        assertEq(token.balanceOf(address(acceptor)), 1);
        assertEq(token.ownerOf(5), address(acceptor));
        (
            address operator,
            address from,
            uint256 tokenId,
            bytes memory receivedData,

        ) = acceptor.receives(0);
        assertEq(operator, USER1);
        assertEq(from, USER1);
        assertEq(tokenId, 5);
        assertEq(receivedData, data);

        data = abi.encodePacked(
            keccak256("piece1"),
            keccak256("piece2"),
            "added data"
        );
        vm.prank(USER1);
        token.setApprovalForAll(USER2, true);
        vm.expectEmit(true, true, true, true);
        emit Transfer(USER1, address(acceptor), 4);
        vm.prank(USER2);
        token.safeTransferFrom(USER1, address(acceptor), 4, data);
        assertEq(token.balanceOf(USER1), 3);
        assertEq(token.balanceOf(address(acceptor)), 2);
        assertEq(token.ownerOf(4), address(acceptor));
        (operator, from, tokenId, receivedData, ) = acceptor.receives(1);
        assertEq(operator, USER2);
        assertEq(from, USER1);
        assertEq(tokenId, 4);
        assertEq(receivedData, data);

        data = "";
        vm.prank(USER2);
        token.approve(USER3, 3);
        vm.expectEmit(true, true, true, true);
        emit Transfer(USER1, address(acceptor), 3);
        vm.prank(USER3);
        token.safeTransferFrom(USER1, address(acceptor), 3, data);
        assertEq(token.balanceOf(USER1), 2);
        assertEq(token.balanceOf(address(acceptor)), 3);
        assertEq(token.ownerOf(3), address(acceptor));
        (operator, from, tokenId, receivedData, ) = acceptor.receives(2);
        assertEq(operator, USER3);
        assertEq(from, USER1);
        assertEq(tokenId, 3);
        assertEq(receivedData, data);
    }

    function testBurn() public {
        token.mint(USER1, 4);

        vm.expectEmit(true, true, true, true);
        emit Transfer(USER1, address(0), 3);
        token.burn(3);

        vm.expectRevert(IERC721H.OwnerQueryForNonexistentToken.selector);
        token.ownerOf(3);

        assertEq(token.ownerOf(1), USER1);
        assertEq(token.ownerOf(2), USER1);
        assertEq(token.ownerOf(4), USER1);
        assertEq(token.totalSupply(), 3);
        assertEq(token.balanceOf(USER1), 3);

        token.mint(USER2, 10);
        assertEq(token.totalSupply(), 13);

        vm.expectEmit(true, true, true, true);
        emit Transfer(USER1, address(0), 4);
        token.burn(4);

        assertEq(token.ownerOf(5), USER2);
        assertEq(token.ownerOf(6), USER2);
    }

    function testSupportsInterface() public {
        assertEq(token.supportsInterface(0x01ffc9a7), true);
        assertEq(token.supportsInterface(0x80ac58cd), true);
        assertEq(token.supportsInterface(0x5b5e139f), true);
        assertEq(token.supportsInterface(0x01ffc9a6), false);
        assertEq(token.supportsInterface(0x00000000), false);
    }

    function testShuffle() public {
        bytes32 seed = keccak256("very random sentence, 98179878798");
        uint256 rounds = 45;
        uint256 indexCount = 1000;

        Set indices = new Set();

        for (uint256 i; i < indexCount; i++) {
            uint256 resIndex = token.shuffle(seed, i, indexCount, rounds);
            bool unique = indices.add(resIndex);
            if (unique) {
                rev[resIndex] = i;
            } else {
                uint256 collided = rev[resIndex];
                fail(
                    string(
                        abi.encodePacked(
                            "collision ",
                            collided.toString(),
                            " <--> ",
                            i.toString()
                        )
                    )
                );
            }
        }

        assertEq(indices.size(), indexCount, "not all in set");
        assertEq(indices.min(), 0, "above bound");
    }

    function runDebug() public {
        setUp();
        testShuffle();
    }
}
