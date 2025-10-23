// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC20} from "@solady/tokens/ERC20.sol";

/// @title IRegistry
interface IRegistry {
    /// @notice Status of a service in the registry
    /// @dev Unused
    /// @param NEW Initial state when service is created
    /// @param VALIDATED Service has been validated/approved
    /// @param BANNED Service has been banned from the platform
    /// @param CANCELLED Service has been cancelled by the owner
    enum Status {
        NEW,
        VALIDATED,
        BANNED,
        CANCELLED
    }

    /// @notice User structure
    /// @param profile Ideally an IPFS hash, for now simply a string
    /// @param stake Amount of tokens staked by the user
    struct User {
        string profile;
        uint256 stake;
    }

    /// @notice Service listing structure
    /// @dev
    /// @param id Unique identifier for the service
    /// @param owner Address of the service provider
    /// @param status Current status of the service
    /// @param description Ideally an IPFS hash, for now simply a string
    struct Service {
        uint40 id;
        address tasker;
        Status status;
        string description;
    }

    /// @notice Service rating structure
    /// @dev
    /// @param rating A numerical rating, between 0 to 5
    /// @param review Ideally an IPFS hash, for now simply a string
    struct Rating {
        address reviewer;
        uint8 rating;
        string review;
    }

    /// @notice Deal structure
    /// @dev
    /// @param id ID of the deal
    /// @param serviceId ID of the service
    /// @token Address of the token being used for the deal
    /// @param price Price of the service
    /// @param beneficiary Address of the beneficiary
    struct Deal {
        uint40 id;
        uint40 serviceId;
        address beneficiary;
        // address token;
        uint256 agreementId;
        uint256 price;
    }
    // DealStatus status?
    // uint32 timeout?

    //////////////////////////////////////////////////////
    /////////////////////// EVENTS ///////////////////////
    //////////////////////////////////////////////////////

    /// @notice Emitted when a user stakes tokens
    /// @param _user Address of the user who staked
    /// @param _amount Amount of tokens staked
    event Staked(address _user, uint256 _amount);

    /// @notice Emitted when a user unstakes tokens
    /// @param _user Address of the user who unstaked
    /// @param _amount Amount of tokens unstaked
    event Unstaked(address _user, uint256 _amount);

    /// @notice Emitted when a user updates their profile
    /// @param _user Address of the user who updated their profile
    event ProfileSet(address _user);

    /// @notice Emitted when a new service is created
    /// @param _serviceId The new service's id
    event ServiceCreated(uint40 _serviceId);

    /// @notice Emitted when a service is updated
    /// @param _serviceId The updated service's id
    /// @param _description The new description of the service
    event ServiceUpdated(uint40 _serviceId, string _description);

    /// @notice Emitted when a deal is created
    /// @param _dealId The new deal's id
    event DealCreated(uint40 _dealId);

    /// @notice Emitted when a service receives a rating
    /// @param _serviceId The rated service's id
    /// @param _rating The rating given
    event Rated(uint40 _serviceId, uint8 _rating);

    //////////////////////////////////////////////////////
    /////////////////////// ERRORS ///////////////////////
    //////////////////////////////////////////////////////

    /// @notice Emitted when a service rating is disputed
    /// @param _serviceId The disputed service's id
    event Disputed(uint40 _serviceId);

    /// @notice Error thrown when an invalid amount is provided
    error InvalidAmount();

    /// @notice Error thrown when user has insufficient staked tokens
    error InsufficientStake();

    /// @notice Error thrown when the caller is not authorized
    error Unauthorized();

    /// @notice Error thrown when dispute resolver is not set
    error DisputeResolverNotSet();

    /// @notice Thrown when the beneficiary address is zero
    error InvalidBeneficiary();

    //////////////////////////////////////////////////////
    ////////////////////// FUNCTIONS /////////////////////
    //////////////////////////////////////////////////////

    /// @notice Stake tokens in the registry
    /// @param _amount Amount of tokens to stake
    function stake(uint256 _amount) external;

    /// @notice Unstake tokens from the registry
    /// @param _amount Amount of tokens to unstake
    function unstake(uint256 _amount) external;

    /// @notice Sets or updates a user's profile
    /// @param _profile Ideally an IPFS hash, for now simply a string
    function setProfile(string calldata _profile) external;

    /// @notice Creates a new service listing
    /// @param _description Ideally an IPFS hash, for now simply a string
    function addService(string calldata _description) external;

    /// @notice Updates an existing service listing
    /// @param _serviceId ID of the service to update
    /// @param _description Ideally an IPFS hash, for now simply a containing the new description
    function updateService(uint40 _serviceId, string calldata _description) external;

    /// @notice Submits a rating for a service
    /// @param _serviceId ID of the service to rate
    /// @param _rating A numerical rating, between 0 to 5
    /// @param _review Ideally an IPFS hash, for now simply an arbitrary string
    function rate(uint40 _serviceId, uint8 _rating, string calldata _review) external;

    /// @notice Initiates a dispute
    /// @dev
    /// @param _serviceId ID of the service with disputed rating
    function dispute(uint40 _serviceId) external;

    /// @notice Creates a deal for a service
    /// @param _serviceId ID of the service
    /// @param _price Price of the deal
    /// @param _beneficiary Address of the beneficiary
    /// @param _agreementURI URI for the agreement
    function createDeal(
        uint40 _serviceId,
        uint256 _price,
        address _beneficiary,
        string calldata _agreementURI
    ) external;

    /// @notice Sets the dispute resolver address
    /// @dev
    /// @param _disputeResolver Address of the dispute resolver\
    function setDisputeResolver(address _disputeResolver) external;
}
