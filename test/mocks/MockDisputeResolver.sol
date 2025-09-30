// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IDisputeResolver} from "../../src/interfaces/IDisputeResolver.sol";

contract MockDisputeResolver is IDisputeResolver {
    function dispute(uint40 _serviceId) external pure {
        // Simulate dispute resolution
        // In a real implementation, this would handle dispute logic
        _serviceId; // Suppress unused parameter warning
    }
}