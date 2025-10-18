// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Registry} from "../../../src/contracts/Registry.sol";
import {Badges} from "../../../src/contracts/Badges.sol";
import {IRegistry} from "../../../src/interfaces/IRegistry.sol";
import {MockEscrow} from "../../mocks/MockEscrow.sol";
import {MockToken} from "../../mocks/MockToken.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract RegistryStakeTest is Test {
    Registry public registry;
    MockToken public token;
    Badges public badges;
    MockEscrow public escrow;

    // Test accounts
    address public alice;
    address public bob;

    // Stake amounts
    uint256 constant INITIAL_BALANCE = 1000e18;
    uint256 constant STANDARD_STAKE = 100e18;
    uint256 constant MAX_UINT256 = type(uint256).max;

    // Events to test
    event Staked(address _user, uint256 _amount);

    function setUp() public {
        // Setup test users
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        // Deploy mock contracts
        token = new MockToken("TestToken", "TTK");
        badges = new Badges(address(this));
        escrow = new MockEscrow();

        // Deploy Registry
        registry = new Registry(address(token), address(badges), address(escrow));

        // Fund test users
        token.mint(alice, INITIAL_BALANCE);
        token.mint(bob, INITIAL_BALANCE);

        // Approve token spending for the registry
        vm.prank(alice);
        token.approve(address(registry), type(uint256).max);

        vm.prank(bob);
        token.approve(address(registry), type(uint256).max);
    }

    // Error Cases
    function test_stake_RevertWhen_ZeroAmount() public {
        vm.expectRevert(IRegistry.InvalidAmount.selector);
        registry.stake(0);
    }

    function test_stake_RevertWhen_InsufficientBalance() public {
        // Transfer away all tokens to cause insufficient balance
        vm.prank(alice);
        token.transfer(bob, INITIAL_BALANCE);

        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, alice, 0, STANDARD_STAKE)
        );
        vm.prank(alice);
        registry.stake(STANDARD_STAKE);
    }

    function test_stake_RevertWhen_InsufficientAllowance() public {
        // Revoke all approvals
        vm.prank(alice);
        token.approve(address(registry), 0);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector, address(registry), 0, STANDARD_STAKE
            )
        );
        vm.prank(alice);
        registry.stake(STANDARD_STAKE);
    }

    // Success Cases
    function test_stake_SingleStake() public {
        uint256 initialRegistryBalance = token.balanceOf(address(registry));
        (, uint256 initialUserStake) = registry.users(alice);

        vm.prank(alice);
        registry.stake(STANDARD_STAKE);

        // Check Registry token balance increased
        assertEq(
            token.balanceOf(address(registry)),
            initialRegistryBalance + STANDARD_STAKE,
            "Registry token balance should increase"
        );

        // Check user stake increased
        (, uint256 finalUserStake) = registry.users(alice);
        assertEq(finalUserStake, initialUserStake + STANDARD_STAKE, "User stake should increase");
    }

    function test_stake_MultipleStakes() public {
        // First stake
        vm.prank(alice);
        registry.stake(STANDARD_STAKE);

        // Second stake
        vm.prank(alice);
        registry.stake(STANDARD_STAKE);

        // Check total stake
        (, uint256 totalStake) = registry.users(alice);
        assertEq(totalStake, STANDARD_STAKE * 2, "User should be able to stake multiple times");
    }

    function test_stake_MultipleUsers() public {
        // Stake with Alice
        vm.prank(alice);
        registry.stake(STANDARD_STAKE);

        // Stake with Bob
        vm.prank(bob);
        registry.stake(STANDARD_STAKE * 2);

        // Check individual stakes
        (, uint256 aliceStake) = registry.users(alice);
        (, uint256 bobStake) = registry.users(bob);
        assertEq(aliceStake, STANDARD_STAKE, "Alice's stake incorrect");
        assertEq(bobStake, STANDARD_STAKE * 2, "Bob's stake incorrect");
    }

    // Event Testing
    function test_stake_EmitsStakedEvent() public {
        vm.expectEmit(true, false, false, true);
        emit Staked(alice, STANDARD_STAKE);

        vm.prank(alice);
        registry.stake(STANDARD_STAKE);
    }

    // Edge Cases
    function test_stake_MaxUint256Amount() public {
        // Create a user with max token balance
        address richUser = makeAddr("richUser");

        // Expect revert when minting max tokens (should cause TotalSupplyOverflow)
        vm.expectRevert(); // TotalSupplyOverflow or similar
        token.mint(richUser, MAX_UINT256);
    }

    // Gas Snapshot
    function test_stake_GasConsumption() public {
        vm.prank(alice);
        registry.stake(STANDARD_STAKE);
    }
}
