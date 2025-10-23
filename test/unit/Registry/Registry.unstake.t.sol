// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Registry} from "../../../src/contracts/Registry.sol";
import {Badges} from "../../../src/contracts/Badges.sol";
import {IRegistry} from "../../../src/interfaces/IRegistry.sol";
import {MockEscrow} from "../../mocks/MockEscrow.sol";
import {MockToken} from "../../mocks/MockToken.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RegistryUnstakeTest is Test {
    Registry public registry;
    MockToken public token;
    MockEscrow public escrow;
    Badges public badges;

    // Test users
    address internal alice;
    address internal bob;
    uint256 internal constant INITIAL_BALANCE = 1000e18;
    uint256 internal constant STAKE_AMOUNT = 500e18;

    // Events to test
    event Unstaked(address _user, uint256 _amount);

    function setUp() public {
        // Setup test users
        alice = makeAddr("Alice");
        bob = makeAddr("Bob");

        // Deploy mock contracts
        token = new MockToken("TestToken", "TTK");
        badges = new Badges(address(this));
        escrow = new MockEscrow();

        // Deploy registry
        registry = new Registry(address(token), address(badges), address(escrow));

        // Mint tokens to test users and setup stakes
        token.mint(alice, INITIAL_BALANCE);
        token.mint(bob, INITIAL_BALANCE);

        // Setup allowances and stakes
        vm.startPrank(alice);
        token.approve(address(registry), type(uint256).max);
        registry.stake(STAKE_AMOUNT);
        vm.stopPrank();

        vm.startPrank(bob);
        token.approve(address(registry), type(uint256).max);
        registry.stake(STAKE_AMOUNT / 2);
        vm.stopPrank();
    }

    // ERROR CASES

    /// @notice Test unstaking 0 amount reverts with InvalidAmount
    function test_unstake_zeroAmount() public {
        vm.prank(alice);
        vm.expectRevert(IRegistry.InvalidAmount.selector);
        registry.unstake(0);
    }

    /// @notice Test unstaking more than staked amount reverts with InsufficientStake
    function test_unstake_moreThanStaked() public {
        vm.prank(alice);
        vm.expectRevert(IRegistry.InsufficientStake.selector);
        registry.unstake(STAKE_AMOUNT + 1);
    }

    /// @notice Test unstaking when no stake exists
    function test_unstake_noStake() public {
        address charlie = makeAddr("Charlie");

        token.mint(charlie, INITIAL_BALANCE);

        vm.prank(charlie);
        vm.expectRevert(IRegistry.InsufficientStake.selector);
        registry.unstake(1);
    }

    // SUCCESS CASES

    /// @notice Test successful full unstaking
    function test_unstake_full() public {
        // Prepare balance check
        uint256 initialUserBalance = token.balanceOf(alice);
        uint256 initialRegistryBalance = token.balanceOf(address(registry));

        // Perform unstake
        vm.startPrank(alice);
        registry.unstake(STAKE_AMOUNT);
        vm.stopPrank();

        // Assertions
        (, uint256 finalStake) = registry.users(alice);
        assertEq(finalStake, 0, "User stake should be zero after full unstake");
        assertEq(
            token.balanceOf(alice),
            initialUserBalance + STAKE_AMOUNT,
            "User token balance should increase by unstaked amount"
        );
        assertEq(
            token.balanceOf(address(registry)),
            initialRegistryBalance - STAKE_AMOUNT,
            "Registry token balance should decrease"
        );
    }

    /// @notice Test successful partial unstaking
    function test_unstake_partial() public {
        uint256 partialAmount = STAKE_AMOUNT / 2;

        // Prepare balance check
        uint256 initialUserBalance = token.balanceOf(bob);
        uint256 initialRegistryBalance = token.balanceOf(address(registry));
        (, uint256 initialUserStake) = registry.users(bob);

        // Perform unstake
        vm.prank(bob);
        registry.unstake(partialAmount);

        // Assertions
        (, uint256 finalUserStake) = registry.users(bob);
        assertEq(finalUserStake, initialUserStake - partialAmount, "User stake should decrease by unstaked amount");
        assertEq(
            token.balanceOf(bob),
            initialUserBalance + partialAmount,
            "User token balance should increase by unstaked amount"
        );
        assertEq(
            token.balanceOf(address(registry)),
            initialRegistryBalance - partialAmount,
            "Registry token balance should decrease"
        );
    }

    // EVENT TESTING

    /// @notice Test Unstaked event is emitted with correct parameters
    function test_unstake_event() public {
        vm.expectEmit(true, false, false, true);
        emit Unstaked(alice, STAKE_AMOUNT);

        vm.prank(alice);
        registry.unstake(STAKE_AMOUNT);
    }

    // EDGE CASES

    /// @notice Test unstaking after multiple stakes
    function test_unstake_multipleStakes() public {
        uint256 additionalStake = 250e18;

        // Additional stake
        vm.startPrank(alice);
        registry.stake(additionalStake);

        uint256 initialUserBalance = token.balanceOf(alice);
        uint256 initialRegistryBalance = token.balanceOf(address(registry));
        (, uint256 initialUserStake) = registry.users(alice);

        // Unstake partial amount
        registry.unstake(STAKE_AMOUNT + additionalStake / 2);
        vm.stopPrank();

        // Assertions
        (, uint256 finalUserStake) = registry.users(alice);
        assertEq(
            finalUserStake,
            initialUserStake - (STAKE_AMOUNT + additionalStake / 2),
            "User stake should decrease correctly after multiple stakes"
        );
        assertEq(
            token.balanceOf(alice),
            initialUserBalance + (STAKE_AMOUNT + additionalStake / 2),
            "User token balance should increase correctly"
        );
        assertEq(
            token.balanceOf(address(registry)),
            initialRegistryBalance - (STAKE_AMOUNT + additionalStake / 2),
            "Registry token balance should decrease"
        );
    }

    /// @notice Test maximum stake unstaking for different users
    function test_unstake_maximumStake() public {
        address[] memory users = new address[](3);
        users[0] = alice;
        users[1] = bob;
        users[2] = makeAddr("Charlie");

        // Stake for each user
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(users[i]);
            token.mint(users[i], INITIAL_BALANCE);
            token.approve(address(registry), type(uint256).max);
            registry.stake(INITIAL_BALANCE);

            (, uint256 userStake) = registry.users(users[i]);
            registry.unstake(userStake);

            (, uint256 finalStake) = registry.users(users[i]);
            assertEq(finalStake, 0, "User stake should be zero after unstaking maximum");
            vm.stopPrank();
        }
    }

    /// @dev Snapshot to check gas costs
    function test_unstake_gas() public {
        vm.startPrank(alice);
        uint256 gasStart = gasleft();
        registry.unstake(STAKE_AMOUNT);
        uint256 gasUsed = gasStart - gasleft();
        console.log("Unstake Gas Used:", gasUsed);
        vm.stopPrank();
    }
}
