// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC20Mock} from "../../mocks/ERC20Mock.sol";

/// @title MaldoToken
/// @notice Currently unused.
contract MaldoToken is ERC20Mock {
    constructor() {}

    function name() public pure override returns (string memory _name) {
        _name = "MaldoToken";
    }

    function symbol() public pure override returns (string memory _symbol) {
        _symbol = "MALDO";
    }
}
