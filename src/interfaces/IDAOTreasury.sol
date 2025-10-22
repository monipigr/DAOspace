// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

interface IDAOTreasury {
    function spendFunds(uint256 proposalId, address recipient, uint256 amount, address token) external;
    function approveProposal(uint256 proposalId) external;
}