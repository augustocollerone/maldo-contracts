// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IEscrow} from "@kleros/escrow-v2/interfaces/IEscrow.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEscrowCustomBuyer is IEscrow, IERC20 {
    /// @dev Create a native transaction with custom buyer.
    /// @param _deadline Time after which a party can automatically execute the arbitrable transaction.
    /// @param _transactionUri The IPFS Uri Hash of the transaction.
    /// @param _buyer Buyer's address.
    /// @param _seller The recipient of the transaction.
    /// @return transactionID The index of the transaction.
    function createNativeTransactionCustomBuyer(
        uint256 _deadline,
        string memory _transactionUri,
        address payable _buyer,
        address payable _seller
    ) external payable returns (uint256 transactionID);

    /// @dev Create an ERC20 transaction with custom buyer address.
    /// @param _amount The amount of tokens in this transaction.
    /// @param _token The ERC20 token contract.
    /// @param _deadline Time after which a party can automatically execute the arbitrable transaction.
    /// @param _transactionUri The IPFS Uri Hash of the transaction.
    /// @param _buyer Buyer's address.
    /// @param _seller The recipient of the transaction.
    /// @return transactionID The index of the transaction.
    function createERC20TransactionCustomBuyer(
        uint256 _amount,
        IERC20 _token,
        uint256 _deadline,
        string memory _transactionUri,
        address payable _buyer,
        address payable _seller
    ) external returns (uint256 transactionID);
}
