// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "./DAOGovernanceToken.sol";
import "./interfaces/IDAOTreasury.sol";

contract DAO is Ownable, ReentrancyGuard {

    DAOGovernanceToken public governanceToken;
    IDAOTreasury public treasury;

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool canceled;
        address recipient;
        uint256 amount;
        address token;
        mapping(address => bool) hasVoted;
        mapping(address => bool) votedFor;
    }

    uint256 public proposalTreshold; // Minimum amount of gobernance tokens needed to create a proposal
    uint256 public votingPeriod;
    uint256 public quorumVotes;

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 startTime, uint256 endTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event ConfigurationUpdated(uint256 proposalTreshold, uint256 votingPeriod, uint256 quorumVotes);
    

    constructor(address _governanceToken, address _treasury, uint256 _proposalTreshold, uint256 _votingPeriod, uint256 _quorumVotes) Ownable(msg.sender) {
        governanceToken = DAOGovernanceToken(_governanceToken);
        treasury = IDAOTreasury(_treasury);
        proposalTreshold = _proposalTreshold;
        votingPeriod = _votingPeriod;
        quorumVotes = _quorumVotes;
    }

    function createProposal(string memory description, address recipient, uint256 amount, address token) external returns(uint256 proposalId) {
        // Comprobaciones
        require(bytes(description).length > 0, "Invalid description");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");
        require(proposalTreshold <= governanceToken.getVotingPower(msg.sender), "Insufficient voting power to create proposal"); 

        // creamos nueva struct y sumamos
        proposalId = proposalCount;
        proposalCount++;
        // asigamos las propiedades de la struct
        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingPeriod;
        proposal.recipient = recipient;
        proposal.amount = amount;
        proposal.token = token;

        // emitimos evento
        emit ProposalCreated(proposalId, msg.sender, description, proposal.startTime, proposal.endTime);
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        // Comprobaciones
        // Que el proposer de la address no es 0
        require(proposal.proposer != address(0), "Proposal not defined");
        // Periodo de votacion activo
        require(block.timestamp > proposal.startTime, "Voting period not started");
        // Si el periodo de votación no ha terminado
        require(proposal.endTime > block.timestamp, "Voting period ended");
        // Si ya hemos votado o no
        require(!proposal.hasVoted[msg.sender], "Already voted");
        // Propuesta no ejecutada
        require(!proposal.executed, "Proposal already executed"); 
        // Propuesta no cancelada
        require(!proposal.canceled, "Proposal canceled"); 

        // Comprobamos poder de voto
        uint256 votes = governanceToken.getVotingPower(msg.sender);
        require(votes > 0, "No voting power");
        // Actualizamos y sumamos el voto
        proposal.hasVoted[msg.sender] = true;
        proposal.votedFor[msg.sender] = support;
        if(support) {
            proposal.forVotes += votes;
        } else {
            proposal.againstVotes += votes;
        }
        // Emitimos el voto
        emit Voted(proposalId, msg.sender, support, votes);
    }

    function cancelProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        // Comprobaciones
        // que existe la propuesta
        require(proposal.proposer != address(0), "Proposal not defined");
        // que no ha sido cancelada
        require(!proposal.canceled, "Proposal already canceled");
        // que no ha sido ejecutada ya
        require(!proposal.executed, "Proposal already executed");
        // que solo la puede ejecutar el owner o el creador de la propuesta
        require(msg.sender == owner() || msg.sender == proposal.proposer, "Not authorized to cancel");

        // Actualizamos estados
        proposal.canceled = true;

        // Emitimos evento
        emit ProposalCanceled(proposalId);
    }

    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        // Comprobaciones
        // que la propuesta exsite
        require(proposal.proposer != address(0), "Proposal not defined");
        // que la propuesta no ha sido ejecutada ya
        require(!proposal.executed, "Proposal already executed");
        // que la propuesta no ha sido cancelada
        require(!proposal.canceled, "Proposal canceled");
        // que el periodo de votación ha terminado
        require(proposal.endTime >= block.timestamp, "Voting period not ended yet");
        // que la propuesta ha alcanzado la participación minima
        require(proposal.forVotes + proposal.againstVotes >= quorumVotes, "Minimum quorum not reached");
        // que la propuesta ha alcanzado el soporte (los votos) necesario
        require(proposal.forVotes > proposal.againstVotes, "Not enought support");
        
        // Actualizamos estados
        proposal.executed = true;

        // Gastamos los fondos
        treasury.approveProposal(proposalId);
        treasury.spendFunds(proposalId, proposal.recipient, proposal.amount, proposal.token);

        //Emitimos eventos
        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Get proposal details
     * @param proposalId ID of the proposal
     * @return proposer Address of the proposer
     * @return description Description of the proposal
     * @return forVotes Number of votes for the proposal
     * @return againstVotes Number of votes against the proposal
     * @return startTime Start time of voting
     * @return endTime End time of voting
     * @return executed Whether the proposal has been executed
     * @return canceled Whether the proposal has been canceled
     * @return recipient Address to receive funds
     * @return amount Amount of funds to be spent
     * @return token Token address for the proposal
     */
    function getProposal(uint256 proposalId) external view returns (
        address proposer,
        string memory description,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 startTime,
        uint256 endTime,
        bool executed,
        bool canceled,
        address recipient,
        uint256 amount,
        address token
    ) {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.proposer,
            proposal.description,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.startTime,
            proposal.endTime,
            proposal.executed,
            proposal.canceled,
            proposal.recipient,
            proposal.amount,
            proposal.token
        );
    }

     /**
     * @dev Check if an address has voted on a proposal
     * @param proposalId ID of the proposal
     * @param voter Address to check
     * @return hasVoted Whether the address has voted
     * @return votedFor Whether the address voted for the proposal (only meaningful if hasVoted is true)
     */
    function getVoteInfo(uint256 proposalId, address voter) external view returns (bool hasVoted, bool votedFor) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.hasVoted[voter], proposal.votedFor[voter]);
    }

    /**
     * @dev Update DAO configuration (only owner)
     * @param _proposalThreshold New proposal threshold
     * @param _votingPeriod New voting period
     * @param _quorumVotes New quorum votes
     */
    function updateConfiguration(
        uint256 _proposalThreshold,
        uint256 _votingPeriod,
        uint256 _quorumVotes
    ) external onlyOwner {
        proposalTreshold = _proposalThreshold;
        votingPeriod = _votingPeriod;
        quorumVotes = _quorumVotes;
        
        emit ConfigurationUpdated(_proposalThreshold, _votingPeriod, _quorumVotes);
    }

    /**
     * @dev Set the treasury contract address (only owner)
     * @param _treasury New treasury contract address
     */
    function setTreasury(address _treasury) external onlyOwner nonReentrant {
        require(_treasury != address(0), "Invalid treasury address");
        treasury = IDAOTreasury(_treasury);
    }
}