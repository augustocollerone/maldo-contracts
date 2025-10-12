// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC20Mock} from "../../mocks/ERC20Mock.sol";

/// @title MaldoToken
/// @notice Currently unused.
contract MaldoToken is ERC20Mock {
    constructor() ERC20Mock() {}
}
