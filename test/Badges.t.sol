// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Badges} from "../src/contracts/Badges.sol";

/// @title BadgesTest
/// @dev Test contract for the simplified Badges ERC1155 implementation
contract BadgesTest is Test {
    Badges public badges;

    address public admin = makeAddr("admin");
    address public minter = makeAddr("minter");
    address public badgeManager = makeAddr("badgeManager");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    function setUp() public {
        vm.startPrank(admin);

        // Deploy the badges contract with only admin parameter
        badges = new Badges(admin);

        // Grant roles to specific addresses
        uint256 minterRole = badges.MINTER_ROLE();
        uint256 badgeManagerRole = badges.BADGE_MANAGER_ROLE();

        badges.grantRoles(minter, minterRole);
        badges.grantRoles(badgeManager, badgeManagerRole);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        BADGE CREATION TESTS
    //////////////////////////////////////////////////////////////*/

    function testCreateBadge() public {
        vm.startPrank(badgeManager);

        uint256 badgeId =
            badges.createBadge("Plumbing University", "a description of some kind, possible an IPFS hash?");

        assertEq(badgeId, 0);

        (string memory name, string memory description, address creator) = badges.badges(0);

        assertEq(name, "Plumbing University");
        assertEq(description, "a description of some kind, possible an IPFS hash?");
        assertEq(creator, badgeManager);

        vm.stopPrank();
    }

    function testCreateBadgeOnlyBadgeManager() public {
        vm.expectRevert();
        vm.prank(user1);
        badges.createBadge("Test", "Test");
    }

    function testCreateBadgeEmptyName() public {
        vm.expectRevert(Badges.InvalidParameters.selector);
        vm.prank(badgeManager);
        badges.createBadge("", "Test");
    }

    /*//////////////////////////////////////////////////////////////
                        BADGE MINTING TESTS
    //////////////////////////////////////////////////////////////*/

    function testMintBadge() public {
        // Create a badge first
        vm.prank(badgeManager);
        badges.createBadge("Test Badge", "Test");

        // Mint the badge
        vm.prank(minter);
        badges.mint(user1, 0, 1);

        assertEq(badges.balanceOf(user1, 0), 1);
        assertTrue(badges.hasBadge(user1, 0));
        assertEq(badges.totalSupply(0), 1);
    }

    function testMintBadgeOnlyMinter() public {
        vm.prank(badgeManager);
        badges.createBadge("Test Badge", "Test");

        vm.expectRevert();
        vm.prank(user1);
        badges.mint(user1, 0, 1);
    }

    function testMintBatch() public {
        vm.startPrank(badgeManager);
        badges.createBadge("Badge 1", "Test");
        badges.createBadge("Badge 2", "Test");
        vm.stopPrank();

        uint256[] memory badgeIds = new uint256[](2);
        badgeIds[0] = 0;
        badgeIds[1] = 1;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        vm.prank(minter);
        badges.mintBatch(user1, badgeIds, amounts);

        assertEq(badges.balanceOf(user1, 0), 1);
        assertEq(badges.balanceOf(user1, 1), 1);
    }

    /*//////////////////////////////////////////////////////////////
                        TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/

    function testTransferOnlyCreator() public {
        vm.prank(badgeManager);
        badges.createBadge("Test Badge", "Test");

        vm.prank(minter);
        badges.mint(user1, 0, 1);

        // Creator can transfer tokens (minter gives creator a token first)
        vm.prank(minter);
        badges.mint(badgeManager, 0, 1); // Give creator a token first

        vm.prank(badgeManager);
        badges.safeTransferFrom(badgeManager, user2, 0, 1, "");

        assertEq(badges.balanceOf(badgeManager, 0), 0);
        assertEq(badges.balanceOf(user2, 0), 1);

        // Non-creator cannot transfer even their own tokens
        vm.expectRevert(Badges.CannotTransfer.selector);
        vm.prank(user1);
        badges.safeTransferFrom(user1, user2, 0, 1, "");
    }

    function testBatchTransferOnlyCreator() public {
        vm.startPrank(badgeManager);
        badges.createBadge("Badge 1", "Test");
        badges.createBadge("Badge 2", "Test");
        vm.stopPrank();

        uint256[] memory badgeIds = new uint256[](2);
        badgeIds[0] = 0;
        badgeIds[1] = 1;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        // Mint tokens to the creator first for valid transfer (using minter)
        vm.prank(minter);
        badges.mintBatch(badgeManager, badgeIds, amounts);

        // Creator can batch transfer their own tokens
        vm.prank(badgeManager);
        badges.safeBatchTransferFrom(badgeManager, user2, badgeIds, amounts, "");

        assertEq(badges.balanceOf(badgeManager, 0), 0);
        assertEq(badges.balanceOf(badgeManager, 1), 0);
        assertEq(badges.balanceOf(user2, 0), 1);
        assertEq(badges.balanceOf(user2, 1), 1);

        // Now mint to a non-creator and test restriction
        vm.prank(minter);
        badges.mintBatch(user1, badgeIds, amounts);

        // Non-creator cannot batch transfer
        vm.expectRevert(Badges.CannotTransfer.selector);
        vm.prank(user1);
        badges.safeBatchTransferFrom(user1, user2, badgeIds, amounts, "");
    }

    /*//////////////////////////////////////////////////////////////
                        UPDATE METADATA TESTS
    //////////////////////////////////////////////////////////////*/

    function testUpdateBadgeMetadata() public {
        vm.prank(badgeManager);
        badges.createBadge("Original Name", "Original Description");

        vm.prank(badgeManager);
        badges.updateBadgeMetadata(0, "Updated Name", "Updated Description");

        (string memory name, string memory description, address creator) = badges.badges(0);

        assertEq(name, "Updated Name");
        assertEq(description, "Updated Description");
        assertEq(creator, badgeManager);
    }

    function testUpdateBadgeMetadataOnlyBadgeManager() public {
        vm.prank(badgeManager);
        badges.createBadge("Test Badge", "Test");

        vm.expectRevert();
        vm.prank(user1);
        badges.updateBadgeMetadata(0, "Hacked", "Hacked");
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function testURI() public {
        string memory expectedURI = string(abi.encodePacked("https://api.badges.com/", "123"));
        assertEq(badges.uri(123), expectedURI);
    }

    function testHasBadge() public {
        vm.prank(badgeManager);
        badges.createBadge("Test Badge", "Test");

        assertFalse(badges.hasBadge(user1, 0));

        vm.prank(minter);
        badges.mint(user1, 0, 1);

        assertTrue(badges.hasBadge(user1, 0));
    }

    /*//////////////////////////////////////////////////////////////
                        ACCESS CONTROL TESTS
    //////////////////////////////////////////////////////////////*/

    function testOwnerCanGrantRoles() public {
        uint256 minterRole = badges.MINTER_ROLE();

        vm.prank(admin);
        badges.grantRoles(user1, minterRole);

        assertTrue(badges.hasAnyRole(user1, minterRole));
    }

    function testNonOwnerCannotGrantRoles() public {
        uint256 minterRole = badges.MINTER_ROLE();

        vm.expectRevert();
        vm.prank(user1);
        badges.grantRoles(user2, minterRole);
    }

    /*//////////////////////////////////////////////////////////////
                        ERROR HANDLING TESTS
    //////////////////////////////////////////////////////////////*/

    function testInvalidParameters() public {
        vm.expectRevert(Badges.InvalidParameters.selector);
        new Badges(address(0));
    }

    /*//////////////////////////////////////////////////////////////
                        INTERFACE SUPPORT TESTS
    //////////////////////////////////////////////////////////////*/

    function testSupportsInterface() public {
        // Test ERC165
        assertTrue(badges.supportsInterface(0x01ffc9a7));
        // Test ERC1155
        assertTrue(badges.supportsInterface(0xd9b67a26));
        // Test ERC1155MetadataURI
        assertTrue(badges.supportsInterface(0x0e89341c));
        // Test unsupported interface
        assertFalse(badges.supportsInterface(0xdeadbeef));
    }
}
