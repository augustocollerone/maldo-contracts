// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

interface IDisputeResolver {
    function dispute(uint40 _serviceId) external;
}
