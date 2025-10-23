// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IEscrow} from "@kleros/escrow-v2/interfaces/IEscrow.sol";

contract MockEscrow is IEscrow {
    uint256 private _mockAgreementId;

    function createERC20Transaction(
        uint256 _amount,
        IERC20 _token,
        uint256 _timeout,
        string calldata _agreementURI,
        address payable _receiver
    ) external returns (uint256 _agreementId) {
        // In a mock, just return a simple incrementing agreement ID
        return ++_mockAgreementId;
    }

    function createNativeTransaction(
        uint256,
        string memory,
        address payable
    ) external payable returns (uint256) {
        return ++_mockAgreementId;
    }

    function pay(uint256, uint256) external pure {}
    function reimburse(uint256, uint256) external pure {}
    function executeTransaction(uint256) external pure {}
    function reimburseTransaction(uint256) external pure {}
    function proposeSettlement(uint256, uint256) external pure {}
    function acceptSettlement(uint256) external pure {}
    function payArbitrationFeeByBuyer(uint256) external payable {}
    function payArbitrationFeeBySeller(uint256) external payable {}
    function timeOutByBuyer(uint256) external pure {}
    function timeOutBySeller(uint256) external pure {}

    function arbitrableTransactionStatus(uint256) external pure returns (uint8) {
        return 0;
    }

    function getTransactionCount() external pure returns (uint256) {
        return 0;
    }
}