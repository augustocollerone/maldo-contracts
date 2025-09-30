// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC20} from "@solady/tokens/ERC20.sol";

contract MockToken is ERC20 {
    string private _name;
    string private _symbol;
    uint8 public constant DECIMALS = 18;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    function burn(address _from, uint256 _amount) public {
        _burn(_from, _amount);
    }
}