// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Registry} from "../../../src/contracts/Registry.sol";
import {Badges} from "../../../src/contracts/Badges.sol";
import {IRegistry} from "../../../src/interfaces/IRegistry.sol";
import {MockEscrow} from "../../mocks/MockEscrow.sol";
import {MaliciousEscrow} from "../../mocks/MaliciousEscrow.sol";
import {MockDisputeResolver} from "../../mocks/MockDisputeResolver.sol";
import {MockToken} from "../../mocks/MockToken.sol";

/// @title Registry Vulnerability Tests
/// @notice Tests to validate critical security vulnerabilities identified in audit
/// @dev These tests DEMONSTRATE vulnerabilities - they should FAIL on current code
contract RegistryVulnerabilitiesTest is Test {
    Registry public registry;
    MockToken public token;
    Badges public badges;
    MockEscrow public escrow;
    MaliciousEscrow public maliciousEscrow;

    // Test users
    address public owner;
    address public tasker;
    address public beneficiary;
    address public attacker;
    address public disputeResolver;

    // Test data
    uint256 constant INITIAL_BALANCE = 1000e18;
    uint256 constant DEAL_PRICE = 100e18;

    uint40 public serviceId;
    uint40 public dealId;

    function setUp() public {
        owner = makeAddr("owner");
        tasker = makeAddr("tasker");
        beneficiary = makeAddr("beneficiary");
        attacker = makeAddr("attacker");
        disputeResolver = makeAddr("disputeResolver");

        // Deploy contracts
        token = new MockToken("TestToken", "TTK");
        badges = new Badges(address(this));
        escrow = new MockEscrow();

        vm.prank(owner);
        registry = new Registry(address(token), address(badges), address(escrow));

        // Fund accounts
        token.mint(tasker, INITIAL_BALANCE);
        token.mint(beneficiary, INITIAL_BALANCE);
        token.mint(attacker, INITIAL_BALANCE);

        // Create test service
        vm.prank(tasker);
        registry.addService("Test Service");
        serviceId = 0;
    }

    /*//////////////////////////////////////////////////////////////
                [C-01] NO VALIDATION ON RATING VALUES
    //////////////////////////////////////////////////////////////*/

    /// @notice Tests that ratings > 5 are accepted (vulnerability)
    /// @dev VULNERABILITY: No validation that rating <= 5
    /// EXPECTED: This test should PASS, proving ratings > 5 are allowed
    function test_VULNERABILITY_ratingAboveFive() public {
        // Create a deal first
        vm.prank(tasker);
        registry.createDeal(serviceId, DEAL_PRICE, beneficiary, 1 days, "test-deal");
        dealId = 0;

        console.log("=== RATING VALIDATION VULNERABILITY TEST ===");

        // Attempt to submit rating > 5
        uint8 invalidRating = 255;  // Maximum uint8 value
        string memory review = "This rating breaks the 0-5 scale!";

        vm.prank(beneficiary);
        registry.rate(dealId, invalidRating, review);

        // Verify the invalid rating was accepted
        IRegistry.Rating[] memory ratings = getServiceRatings(serviceId);

        console.log("Rating submitted:", invalidRating);
        console.log("Rating stored:", ratings[0].rating);

        // VULNERABILITY PROOF:
        // If this assertion passes, the vulnerability is CONFIRMED
        assertEq(ratings[0].rating, 255, "Rating of 255 should be stored (vulnerability confirmed)");

        console.log("!!! VULNERABILITY CONFIRMED: Rating > 5 accepted !!!");
        console.log("Expected: Max rating of 5");
        console.log("Actual: Rating of", ratings[0].rating, "was accepted");

        // Test other invalid ratings
        vm.prank(tasker);
        registry.rate(dealId, 100, "Rating of 100");

        ratings = getServiceRatings(serviceId);
        assertEq(ratings[1].rating, 100, "Rating of 100 should be stored");

        console.log("Multiple invalid ratings accepted:", ratings.length, "total ratings");
        console.log("VULNERABILITY STATUS: CRITICAL - No rating validation exists");
    }

    /// @notice Tests various invalid rating values
    function test_VULNERABILITY_variousInvalidRatings() public {
        // Create deal
        vm.prank(tasker);
        registry.createDeal(serviceId, DEAL_PRICE, beneficiary, 1 days, "test-deal");

        // Test multiple invalid ratings
        uint8[] memory invalidRatings = new uint8[](5);
        invalidRatings[0] = 6;    // Just above max
        invalidRatings[1] = 10;   // Double the max
        invalidRatings[2] = 50;   // Far above max
        invalidRatings[3] = 100;  // Very high
        invalidRatings[4] = 255;  // Maximum uint8

        console.log("Testing various invalid ratings:");

        vm.startPrank(beneficiary);
        for (uint i = 0; i < invalidRatings.length; i++) {
            registry.rate(0, invalidRatings[i], "Invalid rating test");

            IRegistry.Rating[] memory ratings = getServiceRatings(serviceId);
            uint8 storedRating = ratings[ratings.length - 1].rating;

            console.log("  Rating", invalidRatings[i], "->", storedRating == invalidRatings[i] ? "ACCEPTED" : "REJECTED");
            assertEq(storedRating, invalidRatings[i], "Invalid rating should be accepted (vulnerability)");
        }
        vm.stopPrank();

        console.log("RESULT: All invalid ratings accepted - VULNERABILITY CONFIRMED");
    }

    /*//////////////////////////////////////////////////////////////
              [C-02] MULTIPLE RATINGS PER DEAL VULNERABILITY
    //////////////////////////////////////////////////////////////*/

    /// @notice Tests that users can rate the same deal multiple times
    /// @dev VULNERABILITY: No prevention of double-rating
    /// EXPECTED: This test should PASS, proving users can spam ratings
    function test_VULNERABILITY_multipleRatingsPerDeal() public {
        // Create deal
        vm.prank(tasker);
        registry.createDeal(serviceId, DEAL_PRICE, beneficiary, 1 days, "test-deal");
        dealId = 0;

        console.log("=== DOUBLE-RATING VULNERABILITY TEST ===");
        console.log("Testing if same user can rate same deal multiple times...");

        // Beneficiary rates the deal 10 times
        vm.startPrank(beneficiary);
        for (uint i = 0; i < 10; i++) {
            registry.rate(dealId, 5, string(abi.encodePacked("Rating #", uint256(i))));
        }
        vm.stopPrank();

        // Check how many ratings exist
        IRegistry.Rating[] memory ratings = getServiceRatings(serviceId);

        console.log("Number of ratings from same user:", ratings.length);
        console.log("Expected: 1 rating per user");
        console.log("Actual:", ratings.length, "ratings accepted");

        // VULNERABILITY PROOF:
        // If user can submit multiple ratings, vulnerability is confirmed
        assertEq(ratings.length, 10, "All 10 ratings should be accepted (vulnerability confirmed)");

        // Verify all ratings are from same user
        for (uint i = 0; i < ratings.length; i++) {
            assertEq(ratings[i].reviewer, beneficiary, "All ratings should be from beneficiary");
        }

        console.log("!!! VULNERABILITY CONFIRMED: User can spam unlimited ratings !!!");
        console.log("ATTACK SCENARIO: Malicious user can manipulate reputation");
    }

    /// @notice Tests both parties can rate the same deal multiple times
    function test_VULNERABILITY_bothPartiesMultipleRatings() public {
        // Create deal
        vm.prank(tasker);
        registry.createDeal(serviceId, DEAL_PRICE, beneficiary, 1 days, "test-deal");
        dealId = 0;

        console.log("=== DUAL-PARTY DOUBLE-RATING TEST ===");

        // Beneficiary rates 5 times
        vm.startPrank(beneficiary);
        for (uint i = 0; i < 5; i++) {
            registry.rate(dealId, 5, "Beneficiary spam rating");
        }
        vm.stopPrank();

        // Tasker rates 5 times
        vm.startPrank(tasker);
        for (uint i = 0; i < 5; i++) {
            registry.rate(dealId, 5, "Tasker spam rating");
        }
        vm.stopPrank();

        IRegistry.Rating[] memory ratings = getServiceRatings(serviceId);

        console.log("Total ratings from both parties:", ratings.length);
        assertEq(ratings.length, 10, "Both parties can spam ratings");

        // Count ratings by each party
        uint beneficiaryCount = 0;
        uint taskerCount = 0;

        for (uint i = 0; i < ratings.length; i++) {
            if (ratings[i].reviewer == beneficiary) beneficiaryCount++;
            if (ratings[i].reviewer == tasker) taskerCount++;
        }

        console.log("Beneficiary ratings:", beneficiaryCount);
        console.log("Tasker ratings:", taskerCount);

        assertEq(beneficiaryCount, 5, "Beneficiary submitted 5 ratings");
        assertEq(taskerCount, 5, "Tasker submitted 5 ratings");

        console.log("VULNERABILITY STATUS: CONFIRMED - No double-rating prevention");
    }

    /// @notice Tests reputation manipulation via spam ratings
    function test_VULNERABILITY_reputationManipulation() public {
        // Scenario: Malicious service provider creates deals with accomplice
        // Then both spam 5-star ratings to inflate reputation

        console.log("=== REPUTATION MANIPULATION ATTACK ===");

        // Create 5 deals with accomplice
        vm.startPrank(tasker);
        for (uint i = 0; i < 5; i++) {
            registry.createDeal(serviceId, DEAL_PRICE, beneficiary, 1 days, "sybil-deal");
        }
        vm.stopPrank();

        // Each party rates each deal 10 times with 5 stars
        for (uint dealIndex = 0; dealIndex < 5; dealIndex++) {
            vm.startPrank(beneficiary);
            for (uint ratingIndex = 0; ratingIndex < 10; ratingIndex++) {
                registry.rate(uint40(dealIndex), 5, "Fake 5-star rating");
            }
            vm.stopPrank();

            vm.startPrank(tasker);
            for (uint ratingIndex = 0; ratingIndex < 10; ratingIndex++) {
                registry.rate(uint40(dealIndex), 5, "Fake 5-star rating");
            }
            vm.stopPrank();
        }

        // Check total ratings
        IRegistry.Rating[] memory ratings = getServiceRatings(serviceId);

        console.log("Total fake ratings created:", ratings.length);
        console.log("Expected: 10 ratings (1 per party per deal, 5 deals)");
        console.log("Actual:", ratings.length, "ratings (vulnerability exploited)");

        // Calculate average (should be 5.0)
        uint256 sum = 0;
        for (uint i = 0; i < ratings.length; i++) {
            sum += ratings[i].rating;
        }
        uint256 average = sum / ratings.length;

        console.log("Average rating:", average, "/ 5");
        console.log("Service appears to have perfect reputation through spam!");

        assertEq(ratings.length, 100, "100 fake ratings created (5 deals * 2 parties * 10 spam each)");
        console.log("!!! CRITICAL: Reputation system can be completely manipulated !!!");
    }

    /*//////////////////////////////////////////////////////////////
              [H-02] SET DISPUTE RESOLVER TO MISSING VALIDATION
    //////////////////////////////////////////////////////////////*/
    
    function test_VULNERABILITY_setDisputeResolverToZeroAddress() public {

        // First set the dispute resolver to a valid address
        vm.prank(owner);
        registry.setDisputeResolver(address(disputeResolver));

        // Try to set the dispute resolver to a zero address
        vm.prank(owner);
        registry.setDisputeResolver(address(0));

        // Verify state change
        assertEq(registry.disputeResolver(), address(0));
    }

    /*//////////////////////////////////////////////////////////////
              [H-04] NO ACCESS CONTROL ON DISPUTE FUNCTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Tests that anyone can dispute any service
    /// @dev VULNERABILITY: dispute() has no access control
    /// EXPECTED: This test should PASS, proving anyone can dispute
    function test_VULNERABILITY_anyoneCanDispute() public {
        console.log("=== DISPUTE ACCESS CONTROL VULNERABILITY ===");

        // Deploy actual mock dispute resolver
        MockDisputeResolver mockResolver = new MockDisputeResolver();
        vm.prank(owner);
        registry.setDisputeResolver(address(mockResolver));

        // Create a service (tasker creates it)
        vm.prank(tasker);
        registry.addService("Service to dispute");
        uint40 targetServiceId = 1;  // Second service (0 was created in setUp)

        uint256 price = 100 ether;
        uint256 duration = 1 days;
        string memory agreementURI = "https://example.com/agreement";

        vm.prank(tasker);
        registry.createDeal(targetServiceId, price, beneficiary, duration, agreementURI);

        uint40 targetDealId = 0;
        
        console.log("Deal created by tasker:", registry.dealsCount());

        console.log("Service created by tasker:", tasker);
        console.log("Attempting dispute by random attacker:", attacker);

        // ATTACK: Random attacker (not involved in service) tries to dispute
        vm.prank(attacker);
        registry.dispute(targetDealId);

        console.log("!!! VULNERABILITY CONFIRMED: Anyone can dispute any service !!!");
        console.log("Attacker successfully disputed service they're not involved with");
        console.log("Expected: Only service participants can dispute");
        console.log("Actual: ANY address can dispute ANY service");

        // If we got here without revert, vulnerability is confirmed
        assertTrue(true, "Dispute succeeded from unauthorized user");
    }

    /// @notice Tests spam attack via unlimited disputes
    function test_VULNERABILITY_spamDisputes() public {
        // Setup
        MockDisputeResolver mockResolver = new MockDisputeResolver();
        vm.prank(owner);
        registry.setDisputeResolver(address(mockResolver));

        console.log("=== DISPUTE SPAM ATTACK ===");
        console.log("Testing if attacker can spam disputes...");

        // Attacker disputes the same service 100 times
        vm.startPrank(attacker);
        for (uint i = 0; i < 100; i++) {
            registry.dispute(serviceId);
        }
        vm.stopPrank();

        console.log("!!! VULNERABILITY CONFIRMED: Attacker spammed 100 disputes !!!");
        console.log("No rate limiting or access control on disputes");

        assertTrue(true, "Spam disputes succeeded");
    }

    /*//////////////////////////////////////////////////////////////
                    [H-03] PRICE/DURATION VALIDATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Tests that deals can be created with 0 price
    /// @dev VULNERABILITY: No minimum price validation
    function test_VULNERABILITY_zeroPriceDeal() public {
        console.log("=== ZERO PRICE DEAL TEST ===");

        // Create deal with 0 price
        vm.prank(tasker);
        registry.createDeal(serviceId, 0, beneficiary, 1 days, "free-service");

        (,,,, uint256 price) = registry.deals(0);

        console.log("Deal created with price:", price);
        assertEq(price, 0, "Zero price deal accepted (vulnerability confirmed)");

        console.log("!!! VULNERABILITY CONFIRMED: Can create deals with 0 price !!!");
    }

    /// @notice Tests that deals can be created with 0 duration
    /// @dev VULNERABILITY: No minimum duration validation
    function test_VULNERABILITY_zeroDurationDeal() public {
        console.log("=== ZERO DURATION DEAL TEST ===");

        // Create deal with 0 duration (expires immediately)
        vm.prank(tasker);
        registry.createDeal(serviceId, DEAL_PRICE, beneficiary, 0, "instant-expire");

        // Check escrow deadline
        (,, address dealBeneficiary, uint256 agreementId,) = registry.deals(0);
        (,, uint256 deadline,,,) = escrow.transactions(agreementId);

        console.log("Block timestamp:", block.timestamp);
        console.log("Deal deadline:", deadline);
        console.log("Time until expiry:", deadline - block.timestamp);

        // Deadline should be block.timestamp + 0 = current timestamp
        assertEq(deadline, block.timestamp, "Deal expires immediately");

        console.log("!!! VULNERABILITY CONFIRMED: Can create deals with 0 duration !!!");
    }

    /// @notice Tests deals with excessive prices
    function test_VULNERABILITY_excessivePriceDeal() public {
        console.log("=== EXCESSIVE PRICE DEAL TEST ===");

        // Create deal with absurdly high price
        uint256 absurdPrice = type(uint256).max;  // Maximum possible value

        vm.prank(tasker);
        registry.createDeal(serviceId, absurdPrice, beneficiary, 1 days, "expensive-deal");

        (,,,, uint256 price) = registry.deals(0);

        console.log("Deal created with price:", price);
        assertEq(price, absurdPrice, "Excessive price accepted");

        console.log("!!! VULNERABILITY CONFIRMED: No maximum price validation !!!");
    }

    /*//////////////////////////////////////////////////////////////
                    [M-04] STRING LENGTH VALIDATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Tests that extremely long strings are accepted
    /// @dev VULNERABILITY: No string length limits (gas griefing)
    function test_VULNERABILITY_extremelyLongDescription() public {
        console.log("=== STRING LENGTH VULNERABILITY TEST ===");

        // Create a very long description (10KB of text)
        string memory longDesc = "";
        for (uint i = 0; i < 100; i++) {
            longDesc = string(abi.encodePacked(
                longDesc,
                "This is a very long description that should probably have a length limit. "
            ));
        }

        uint256 descLength = bytes(longDesc).length;
        console.log("Description length:", descLength, "bytes");

        uint256 gasBefore = gasleft();

        vm.prank(tasker);
        registry.addService(longDesc);

        uint256 gasUsed = gasBefore - gasleft();
        console.log("Gas used for long description:", gasUsed);

        (,, string memory storedDesc) = registry.services(1);
        console.log("Stored description length:", bytes(storedDesc).length, "bytes");

        assertEq(bytes(storedDesc).length, descLength, "Extremely long description accepted");

        console.log("!!! VULNERABILITY CONFIRMED: No string length limits !!!");
        console.log("Potential for gas griefing and storage bloat");
    }

    /// @notice Tests that empty descriptions are accepted
    /// @dev VULNERABILITY: No empty description validation
    function test_VULNERABILITY_emptyDescription() public {
        console.log("=== EMPTY DESCRIPTION TEST ===");

        uint256 gasBefore = gasleft();

        vm.prank(tasker);
        registry.addService("");

        uint256 gasUsed = gasBefore - gasleft();
        console.log("Gas used for empty description:", gasUsed);

        (,, string memory storedDesc) = registry.services(1);
        console.log("Stored description length:", bytes(storedDesc).length, "bytes");

        assertEq(bytes(storedDesc).length, 0, "Empty description accepted");

        console.log("!!! VULNERABILITY CONFIRMED: Empty description accepted !!!");
    }

    /*//////////////////////////////////////////////////////////////
                          HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getServiceRatings(uint40 _serviceId) internal view returns (IRegistry.Rating[] memory) {
        // Count how many ratings exist
        uint256 count = 0;
        while (true) {
            try registry.ratings(_serviceId, count) returns (address, uint8, string memory) {
                count++;
            } catch {
                break;
            }
        }

        // Create array and populate it
        IRegistry.Rating[] memory ratings = new IRegistry.Rating[](count);
        for (uint256 i = 0; i < count; i++) {
            (address reviewer, uint8 rating, string memory review) = registry.ratings(_serviceId, i);
            ratings[i] = IRegistry.Rating(reviewer, rating, review);
        }

        return ratings;
    }
}
