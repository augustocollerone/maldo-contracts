// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Registry} from "../../../src/contracts/Registry.sol";
import {IRegistry} from "../../../src/interfaces/IRegistry.sol";
import {Badges} from "../../../src/contracts/Badges.sol";
import {MockEscrow} from "../../mocks/MockEscrow.sol";
import {MockToken} from "../../mocks/MockToken.sol";

contract RegistryGettersTest is Test {
    Registry public registry;
    MockToken public token;
    Badges public badges;
    MockEscrow public escrow;

    address public deployer;
    address public tasker1;
    address public tasker2;
    address public user1;
    address public user2;

    function setUp() public {
        deployer = makeAddr("deployer");
        tasker1 = makeAddr("tasker1");
        tasker2 = makeAddr("tasker2");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.startPrank(deployer);
        token = new MockToken("Test", "TST");
        badges = new Badges(deployer);
        escrow = new MockEscrow();
        registry = new Registry(address(token), address(badges), address(escrow));
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            getToken TESTS
    //////////////////////////////////////////////////////////////*/

    function test_getToken() public view {
        assertEq(registry.getToken(), address(token));
    }

    function test_escrow() public view {
        assertEq(address(registry.escrow()), address(escrow));
    }

    /*//////////////////////////////////////////////////////////////
                        servicesCount TESTS
    //////////////////////////////////////////////////////////////*/

    function test_servicesCount_Zero() public view {
        assertEq(registry.servicesCount(), 0);
    }

    function test_servicesCount_Single() public {
        vm.prank(tasker1);
        registry.addService("service 1");

        assertEq(registry.servicesCount(), 1);
    }

    function test_servicesCount_Multiple() public {
        vm.prank(tasker1);
        registry.addService("service 1");

        vm.prank(tasker2);
        registry.addService("service 2");

        vm.prank(tasker1);
        registry.addService("service 3");

        assertEq(registry.servicesCount(), 3);
    }

    /*//////////////////////////////////////////////////////////////
                        dealsCount TESTS
    //////////////////////////////////////////////////////////////*/

    function test_dealsCount_Zero() public view {
        assertEq(registry.dealsCount(), 0);
    }

    function test_dealsCount_Single() public {
        // Setup: create service first
        vm.prank(tasker1);
        registry.addService("service 1");

        // Create deal
        vm.prank(tasker1);
        registry.createDeal(0, 100, user1, 1 days, "agreement1");

        assertEq(registry.dealsCount(), 1);
    }

    function test_dealsCount_Multiple() public {
        // Setup: create services first
        vm.prank(tasker1);
        registry.addService("service 1");

        // Create deals
        vm.prank(tasker1);
        registry.createDeal(0, 100, user1, 1 days, "agreement1");

        vm.prank(tasker1);
        registry.createDeal(0, 200, user2, 1 days, "agreement2");

        vm.prank(tasker1);
        registry.createDeal(0, 150, user1, 1 days, "agreement3");

        assertEq(registry.dealsCount(), 3);
    }

    /*//////////////////////////////////////////////////////////////
                    ratings TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ratings_Single() public {
        // Setup: create service and deal
        vm.prank(tasker1);
        registry.addService("service 1");

        vm.prank(tasker1);
        registry.createDeal(0, 100, user1, 1 days, "agreement");

        // Add rating
        vm.prank(user1);
        registry.rate(0, 5, "excellent");

        // Access rating through mapping getter
        (address reviewer, uint8 rating, string memory review) = registry.ratings(0, 0);
        assertEq(reviewer, user1);
        assertEq(rating, 5);
        assertEq(review, "excellent");
    }

    function test_ratings_Multiple() public {
        // Setup: create service and deal
        vm.prank(tasker1);
        registry.addService("service 1");

        vm.prank(tasker1);
        registry.createDeal(0, 100, user1, 1 days, "agreement");

        // Add ratings
        vm.prank(user1);
        registry.rate(0, 5, "excellent");

        vm.prank(tasker1);
        registry.rate(0, 4, "good client");

        // Access first rating
        (address reviewer1, uint8 rating1, string memory review1) = registry.ratings(0, 0);
        assertEq(reviewer1, user1);
        assertEq(rating1, 5);
        assertEq(review1, "excellent");

        // Access second rating
        (address reviewer2, uint8 rating2, string memory review2) = registry.ratings(0, 1);
        assertEq(reviewer2, tasker1);
        assertEq(rating2, 4);
        assertEq(review2, "good client");
    }

    function test_ratings_MultipleDealsAccumulateRatings() public {
        // Setup: create service and multiple deals
        vm.prank(tasker1);
        registry.addService("service 1");

        vm.prank(tasker1);
        registry.createDeal(0, 100, user1, 1 days, "agreement1");

        vm.prank(tasker1);
        registry.createDeal(0, 200, user2, 1 days, "agreement2");

        // Add ratings from different deals
        vm.prank(user1);
        registry.rate(0, 5, "excellent from deal 1");

        vm.prank(user2);
        registry.rate(1, 3, "okay from deal 2");

        // Verify both ratings are stored for service 0
        (address reviewer1, uint8 rating1,) = registry.ratings(0, 0);
        assertEq(reviewer1, user1);
        assertEq(rating1, 5);

        (address reviewer2, uint8 rating2,) = registry.ratings(0, 1);
        assertEq(reviewer2, user2);
        assertEq(rating2, 3);
    }

}
