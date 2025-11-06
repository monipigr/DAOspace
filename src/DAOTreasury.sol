// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "./DAO.sol";

/**
 * @title DAOTreasury
 * @dev Treasury contract for managing DAO funds
 * Allows spending based on approved proposals
 */
contract DAOTreasury is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    DAO public dao;

    // Mapping to track approved spending proposals
    mapping(uint256 => bool) public approvedProposals;
    
    // Mapping to track executed spending proposals
    mapping(uint256 => bool) public executedProposals;

    event ProposalApproved(uint256 indexed proposalId);
    event FundSpent(uint256 indexed proposalId, address indexed recipient, uint256 amount, address token);
    event TreasuryFunded(address indexed sender, uint256 amount);
    event DAOSet(address indexed dao);

    /**
     * @dev Constructor
     * @param _dao Address of the DAO contract
     */
    constructor(address _dao) Ownable(msg.sender) {
        dao = DAO(_dao);
    }

    receive() external payable {
        emit TreasuryFunded(msg.sender, msg.value);
    }

    /**
     * @dev Set the DAO contract address (only owner)
     * @param _dao New DAO contract address
     */
    function setDAO(address _dao) external onlyOwner {
        require(_dao != address(0), "Invalid DAO address");

        dao = DAO(_dao);

        emit DAOSet(_dao);
    }

    /**
     * @dev Spend funds based on an approved proposal
     * @param proposalId ID of the approved proposal
     * @param recipient Address to send funds to
     * @param amount Amount to send
     * @param token Token address (address(0) for ETH)
     */
    function spendFunds(uint256 proposalId, address recipient, uint256 amount, address token) external nonReentrant {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");
        require(approvedProposals[proposalId], "Proposal must be approved");
        require(!executedProposals[proposalId], "Proposal already executed");
        require(msg.sender == address(dao), "Only DAO can send funds");

        executedProposals[proposalId] = true;

        if (token == address(0)) {
            require(amount <= address(this).balance, "Insufficient ETH balance");
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "Transfer failed");
        } else {
            require(amount <= IERC20(token).balanceOf(address(this)), "Insufficient token balance");
            IERC20(token).safeTransfer(recipient, amount);
        }

        emit FundSpent(proposalId, recipient, amount, token);
    }

    /**
     * @dev Approve a proposal for spending (only DAO)
     * @param proposalId ID of the proposal to approve
     */
    function approveProposal(uint256 proposalId) external {
        require(msg.sender == address(dao), "Only DAO can approve proposals");
        require(!approvedProposals[proposalId], "Proposal already approved");
        
        approvedProposals[proposalId] = true;

        emit ProposalApproved(proposalId);
    }

    /**
     * @dev Fund the treasury with ETH
     */
    function fundTreasuryETH() external payable {
        require(msg.value > 0, "Must send ETH");

        emit TreasuryFunded(msg.sender, msg.value);
    }

    /**
     * @dev Fund the treasury with ERC20 tokens
     * @param token Token address
     * @param amount Amount to fund
     */
    function fundTreasuryToken(address token, uint256 amount) external {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than 0");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        emit TreasuryFunded(msg.sender, amount);
    }

    /**
     * @dev Emergency withdrawal (only owner)
     * @param token Token address (address(0) for ETH)
     * @param amount Amount to withdraw
     * @param recipient Address to send funds to
     */
    function emergencyWithdraw(address token, uint256 amount, address recipient) external onlyOwner nonReentrant() {
        require(amount > 0, "Amount must be greater than 0");
        require(recipient != address(0), "Invalid recipient address");

        if (token == address(0)) {
            require(amount <= address(this).balance, "Insufficient ETH balance");
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "Transfer failed");
        } else {
            require(amount <= IERC20(token).balanceOf(address(this)), "Insufficient token balance");
            IERC20(token).safeTransfer(recipient, amount);
        }
    }

}