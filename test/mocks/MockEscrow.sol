// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IEscrowCustomBuyer} from "../../src/interfaces/IEscrowCustomBuyer.sol";

contract MockEscrow is IEscrowCustomBuyer {
    uint256 private _mockAgreementId;

    struct Transaction {
        uint256 amount;
        address token;
        uint256 deadline;
        string transactionUri;
        address payable buyer;
        address payable seller;
    }

    mapping(uint256 => Transaction) public transactions;

    // IEscrowCustomBuyer methods
    function createERC20TransactionCustomBuyer(
        uint256 _amount,
        IERC20 _token,
        uint256 _deadline,
        string memory _transactionUri,
        address payable _buyer,
        address payable _seller
    ) external returns (uint256 transactionID) {
        transactionID = ++_mockAgreementId;
        transactions[transactionID] = Transaction({
            amount: _amount,
            token: address(_token),
            deadline: _deadline,
            transactionUri: _transactionUri,
            buyer: _buyer,
            seller: _seller
        });
    }

    function createNativeTransactionCustomBuyer(
        uint256 _deadline,
        string memory _transactionUri,
        address payable _buyer,
        address payable _seller
    ) external payable returns (uint256 transactionID) {
        return ++_mockAgreementId;
    }

    // IEscrow methods
    function createERC20Transaction(
        uint256 _amount,
        IERC20 _token,
        uint256 _timeout,
        string calldata _agreementURI,
        address payable _receiver
    ) external returns (uint256 _agreementId) {
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

    // IERC20 methods (IEscrowCustomBuyer extends IERC20)
    function totalSupply() external pure returns (uint256) {
        return 0;
    }

    function balanceOf(address) external pure returns (uint256) {
        return 0;
    }

    function transfer(address, uint256) external pure returns (bool) {
        return true;
    }

    function allowance(address, address) external pure returns (uint256) {
        return 0;
    }

    function approve(address, uint256) external pure returns (bool) {
        return true;
    }

    function transferFrom(address, address, uint256) external pure returns (bool) {
        return true;
    }
}