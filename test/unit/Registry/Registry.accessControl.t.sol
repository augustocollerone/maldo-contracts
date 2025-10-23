// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Registry} from "../../../src/contracts/Registry.sol";
import {MockToken} from "../../mocks/MockToken.sol";
import {MockEscrow} from "../../mocks/MockEscrow.sol";
import {Badges} from "../../../src/contracts/Badges.sol";
import {MockDisputeResolver} from "../../mocks/MockDisputeResolver.sol";
import {IRegistry} from "../../../src/interfaces/IRegistry.sol";

contract RegistryAccessControlTest is Test {
    // Contract instances
    Registry public registry;
    MockToken public token;
    MockEscrow public escrow;
    Badges public badges;
    MockDisputeResolver public disputeResolver;

    // Test users
    address public owner;
    address public tasker;
    address public beneficiary;
    address public unauthorized;

    // Service details
    uint40 public serviceId;

    function setUp() public {
        // Deploy mock dependencies
        token = new MockToken("TestToken", "TTK");
        escrow = new MockEscrow();
        badges = new Badges(address(this));

        // Deploy registry as owner
        owner = makeAddr("Owner");
        vm.prank(owner);
        registry = new Registry(address(token), address(badges), address(escrow));

        // Setup test users
        tasker = makeAddr("Tasker");
        beneficiary = makeAddr("Beneficiary");
        unauthorized = makeAddr("Unauthorized");

        // Mint tokens and set initial balances
        token.mint(tasker, 1000 ether);

        vm.startPrank(tasker);
        token.approve(address(registry), 1000 ether);
        registry.stake(100 ether);
        registry.addService("Test Service");
        serviceId = 0; // First service
        vm.stopPrank();
    }

    // Tests for setDisputeResolver
    function test_setDisputeResolver_success() public {
        // Arrange
        disputeResolver = new MockDisputeResolver();

        // Act & Assert
        vm.prank(owner);
        registry.setDisputeResolver(address(disputeResolver));

        // Verify state change
        assertEq(registry.disputeResolver(), address(disputeResolver));
    }

    function test_setDisputeResolver_revertWhen_calledByNonOwner() public {
        // Arrange
        disputeResolver = new MockDisputeResolver();

        // Act & Assert
        vm.prank(unauthorized);
        vm.expectRevert(IRegistry.Unauthorized.selector);
        registry.setDisputeResolver(address(disputeResolver));
    }

    // Tests for updateService
    function test_updateService_revertWhen_calledByNonTasker() public {
        // Arrange
        string memory newDescription = "Updated Service Description";

        // Act & Assert
        vm.prank(unauthorized);
        vm.expectRevert(IRegistry.Unauthorized.selector);
        registry.updateService(serviceId, newDescription);
    }

    // Tests for createDeal

    function test_createDeal_revertWhen_calledByNonTasker() public {
        // Arrange
        uint256 price = 50 ether;
        string memory agreementURI = "https://example.com/agreement";

        // Act & Assert
        vm.prank(unauthorized);
        vm.expectRevert(IRegistry.Unauthorized.selector);
        registry.createDeal(serviceId, price, beneficiary, 1 days, agreementURI);
    }

    function test_createDeal_revertWhen_invalidBeneficiary() public {
        // Act & Assert
        vm.prank(tasker);
        vm.expectRevert(IRegistry.InvalidBeneficiary.selector);
        registry.createDeal(serviceId, 50 ether, address(0), 1 days, "https://example.com/agreement");
    }

    // Tests for rate

    function test_rate_revertWhen_calledByUnauthorized() public {
        // Arrange
        // First create a deal
        uint256 price = 50 ether;
        string memory agreementURI = "https://example.com/agreement";

        // Mint tokens to beneficiary
        vm.startPrank(beneficiary);
        token.mint(beneficiary, 100 ether);
        token.approve(address(registry), 100 ether);
        vm.stopPrank();

        // Create deal
        vm.prank(tasker);
        registry.createDeal(serviceId, price, beneficiary, 1 days, agreementURI);
        uint40 dealId = 0; // First deal

        // Act & Assert
        vm.prank(unauthorized);
        vm.expectRevert(IRegistry.Unauthorized.selector);
        registry.rate(dealId, 5, "Not authorized!");
    }

    // Tests for dispute
    function test_dispute_revertWhen_noDisputeResolver() public {
        // Act & Assert
        vm.expectRevert(IRegistry.DisputeResolverNotSet.selector);
        vm.prank(beneficiary);
        registry.dispute(serviceId);
    }

    function test_dispute_successWhenDisputeResolverSet() public {
        // Arrange
        disputeResolver = new MockDisputeResolver();

        // Set dispute resolver
        vm.prank(owner);
        registry.setDisputeResolver(address(disputeResolver));

        // Act & Assert
        vm.prank(beneficiary);
        registry.dispute(serviceId);
    }
}
