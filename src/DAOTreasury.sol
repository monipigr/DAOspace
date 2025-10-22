// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

import "./DAO.sol";

contract DAOTreasury is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    DAO public dao;

    mapping(uint256 => bool) public approvedProposals;
    mapping(uint256 => bool) executedProposals;

    event ProposalApproved(uint256 indexed proposalId);
    event FundSpent(uint256 indexed proposalId, address indexed recipient, uint256 amount, address token);
    event TreasuryFunded(address indexed sender, uint256 amount);
    event DAOSet(address indexed dao);


    constructor(address _dao) Ownable(msg.sender) {
        dao = DAO(_dao);
    }

    receive() external payable {
        emit TreasuryFunded(msg.sender, msg.value);
    }

    function setDAO(address _dao) external onlyOwner {
        require(_dao != address(0), "Invalid DAO address");

        dao = DAO(_dao);

        emit DAOSet(_dao);
    }

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

    function approveProposal(uint256 proposalId) external {
        // Comprobamos que solo puede aprobar la propuesta la dao
        require(msg.sender == address(dao), "Only DAO can approve proposals");
        // Comprobamos que la propuesta no ha sido aprobada anteriomente
        require(!approvedProposals[proposalId], "Proposal already approved");
        
        // Aprobamos la propuesta
        approvedProposals[proposalId] = true;

        //Emitimos el evento
        emit ProposalApproved(proposalId);
    }

    function fundTreasuryETH() external payable {
        require(msg.value > 0, "Must send ETH");

        emit TreasuryFunded(msg.sender, msg.value);
    }

    function fundTreasuryToken(address token, uint256 amount) external {
        // Comprobaciones
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than 0");

        // Cogemos los fondos del sender con safeTRansferFrom
        // require(IERC20(token).safeTransferFrom(msg.sender, address(this), amount), "Token transfer failed");
        // IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // emitimos evento+
        emit TreasuryFunded(msg.sender, amount);
    }

    function emergencyWithdraw(address token, uint256 amount, address recipient) external onlyOwner nonReentrant() {
        // Comprobaciones
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