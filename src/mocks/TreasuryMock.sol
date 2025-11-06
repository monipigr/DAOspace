// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract TreasuryMock {

    receive() external payable {}

    function approveProposal(uint256 proposalId) external {}

    function spendFunds(uint256 proposalId, address recipient, uint256 amount, address token) external {}
}