// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "../lib/forge-std/src/Test.sol";
import "../src/DAO.sol";
import "../src/DAOTreasury.sol";
import "../src/mocks/GovernanceMockToken.sol";
import "../src/mocks/TreasuryMock.sol";

contract DAOTest is Test {

    DAO public daoContract; 
    DAOTreasury public treasury;
    GovernanceMockToken public daoMockToken;
    TreasuryMock public treasuryMock;

    uint256 proposalTreshold = 5*1e18;
    uint256 votingPeriod = 3 days; 
    uint256 quorumVotes = 10*1e18;

    address owner = address(this);
    address user = vm.addr(1);
    address user2 = vm.addr(2);

    function setUp() public {
        daoMockToken = new GovernanceMockToken("DaoToken", "DAO", 1000 * 1e18);
        treasuryMock = new TreasuryMock();
        daoContract = new DAO(address(daoMockToken), address(treasuryMock), proposalTreshold, votingPeriod, quorumVotes);
        treasury = new DAOTreasury(address(daoContract));
    }

    function test_createProposal() public {
        string memory description = "Public proposal description";
        address recipient = address(treasuryMock);
        uint256 amount = 2*1e18;
        address token = address(daoMockToken);

        uint256 proposalCountBefore = daoContract.proposalCount();

        vm.startPrank(user);

        deal(address(daoMockToken), user, 9*1e18);
        daoContract.createProposal(description, recipient, amount, token);

        (address proposer, string memory createdDescription, ,,,, bool executed, bool canceled ,,,) = daoContract.getProposal(proposalCountBefore);

        vm.stopPrank();

        uint256 proposalCountAfter = daoContract.proposalCount();

        assertEq(proposalCountAfter, proposalCountBefore + 1);
        assertEq(user, proposer);
        assertEq(description, createdDescription);
        assertFalse(executed);
        assertFalse(canceled);
    }

    function test_createProposal_revertIfInvalidDescription() public {
        string memory description = "";
        address recipient = address(treasuryMock);
        uint256 amount = 2*1e18;
        address token = address(daoMockToken);

        vm.startPrank(user);

        deal(address(daoMockToken), user, 9*1e18);
        vm.expectRevert("Invalid description");
        daoContract.createProposal(description, recipient, amount, token);

        vm.stopPrank();
    }

    function test_createProposal_revertIfInvalidRecipientAddress() public {
        string memory description = "Public proposal description";
        address recipient = address(0);
        uint256 amount = 2*1e18;
        address token = address(daoMockToken);

        vm.startPrank(user);

        deal(address(daoMockToken), user, 9*1e18);
        vm.expectRevert("Invalid recipient address");
        daoContract.createProposal(description, recipient, amount, token);

        vm.stopPrank();
    }

    function test_createProposal_revertIfAmount0() public {
        string memory description = "Public proposal description";
        address recipient = address(treasuryMock);
        uint256 amount = 0;
        address token = address(daoMockToken);

        vm.startPrank(user);

        deal(address(daoMockToken), user, 9*1e18);
        vm.expectRevert("Amount must be greater than 0");
        daoContract.createProposal(description, recipient, amount, token);

        vm.stopPrank();
    }

    function test_createProposal_revertIfInsufficientVotingPower() public {
        string memory description = "Public proposal description";
        address recipient = address(treasuryMock);
        uint256 amount = 2*1e18;
        address token = address(daoMockToken);

        vm.startPrank(user);

        deal(address(daoMockToken), user, 4*1e18);
        vm.expectRevert("Insufficient voting power to create proposal");
        daoContract.createProposal(description, recipient, amount, token);

        vm.stopPrank();
    }

    function test_vote_voteFor() public {
        // Create proposal
        vm.startPrank(user);
        deal(address(daoMockToken), user, 9*1e18);
        daoContract.createProposal("Proposal description", address(treasuryMock), 2*1e18, address(daoMockToken));
        vm.stopPrank();

        // Vote
        uint256 proposalId = daoContract.proposalCount() - 1;
        deal(address(daoMockToken), user2, 5*1e18);
        vm.warp(1 days);
        vm.startPrank(user2);
        daoContract.vote(proposalId, true);
        vm.stopPrank();

        (,, uint256 forVotes, ,,,,,,,) = daoContract.getProposal(proposalId);
        (bool hasVoted, bool votedFor) = daoContract.getVoteInfo(proposalId, user2);
        
        assertEq(forVotes, daoMockToken.getVotingPower(user2));
        assertTrue(hasVoted);
        assertTrue(votedFor);
    }

    function test_vote_voteAgainst() public {
        // Create proposal
        vm.startPrank(user);
        deal(address(daoMockToken), user, 9*1e18);
        daoContract.createProposal("Proposal description", address(treasuryMock), 2*1e18, address(daoMockToken));
        vm.stopPrank();

        // Vote
        uint256 proposalId = daoContract.proposalCount() - 1;
        deal(address(daoMockToken), user2, 5*1e18);
        vm.warp(1 days);
        vm.startPrank(user2);
        daoContract.vote(proposalId, false);
        vm.stopPrank();

        (,,, uint256 againstVotes, ,,,,,,) = daoContract.getProposal(proposalId);
        (bool hasVoted, bool votedFor) = daoContract.getVoteInfo(proposalId, user2);
        
        assertEq(againstVotes, daoMockToken.getVotingPower(user2));
        assertTrue(hasVoted);
        assertFalse(votedFor);
    }

    function test_vote_revertIfProposalNotDefined() public {   
        // No previously created a proposal

        // Vote
        deal(address(daoMockToken), user2, 5*1e18);
        vm.warp(1 days);
        vm.startPrank(user2);
        vm.expectRevert("Proposal not defined");
        daoContract.vote(1, false);
        vm.stopPrank();     
    }

    function test_vote_revertIfVotingPeriodNotStarted() public {
        // Create proposal
        vm.startPrank(user);
        deal(address(daoMockToken), user, 9*1e18);
        daoContract.createProposal("Proposal description", address(treasuryMock), 2*1e18, address(daoMockToken));
        vm.stopPrank();

        // Vote
        uint256 proposalId = daoContract.proposalCount() - 1;
        deal(address(daoMockToken), user2, 5*1e18);
        vm.warp(block.timestamp - 1);
        vm.startPrank(user2);
        vm.expectRevert("Voting period not started");
        daoContract.vote(proposalId, false);
        vm.stopPrank();
    }

    function test_vote_revertIfVotingPeriodEnded() public {
        // Create proposal
        vm.startPrank(user);
        deal(address(daoMockToken), user, 9*1e18);
        daoContract.createProposal("Proposal description", address(treasuryMock), 2*1e18, address(daoMockToken));
        vm.stopPrank();

        // Vote
        uint256 proposalId = daoContract.proposalCount() - 1;
        deal(address(daoMockToken), user2, 5*1e18);
        vm.warp(4 days);
        vm.startPrank(user2);
        vm.expectRevert("Voting period ended");
        daoContract.vote(proposalId, true);
        vm.stopPrank();
    }

    function test_vote_revertIfAlreadyVoted() public {
        // Create proposal
        vm.startPrank(user);
        deal(address(daoMockToken), user, 9*1e18);
        daoContract.createProposal("Proposal description", address(treasuryMock), 2*1e18, address(daoMockToken));
        vm.stopPrank();

        // Vote
        uint256 proposalId = daoContract.proposalCount() - 1;
        deal(address(daoMockToken), user2, 5*1e18);
        vm.warp(2 days);
        vm.startPrank(user2);
        daoContract.vote(proposalId, true);
        vm.expectRevert("Already voted");
        daoContract.vote(proposalId, false);
        vm.stopPrank();
    }
    
    function test_vote_revertIfProposalAlreadyExecuted() public {
        // Create proposal
        vm.startPrank(user);
        deal(address(daoMockToken), user, 9*1e18);
        daoContract.createProposal("Proposal description", address(treasuryMock), 2*1e18, address(daoMockToken));
        vm.stopPrank();

        // Vote
        uint256 proposalId = daoContract.proposalCount() - 1;
        deal(address(daoMockToken), user2, 11*1e18);
        vm.warp(2 days);
        vm.startPrank(user2);
        daoContract.vote(proposalId, true);
        vm.stopPrank();

        // Execute proposal
        vm.startPrank(address(daoContract));
        treasuryMock.approveProposal(proposalId);
        treasuryMock.spendFunds(proposalId, address(treasuryMock), 11*1e18, address(daoMockToken));
        vm.stopPrank();
        daoContract.executeProposal(proposalId);

        // Vote again when proposal already executed
        vm.expectRevert("Proposal already executed");
        daoContract.vote(proposalId, true);
    }

    function test_vote_revertIfProposalCanceled() public {
        // Create proposal
        vm.startPrank(user);
        deal(address(daoMockToken), user, 9*1e18);
        daoContract.createProposal("Proposal description", address(treasuryMock), 2*1e18, address(daoMockToken));
        // Cancel proposal
        uint256 proposalId = daoContract.proposalCount() - 1;
        daoContract.cancelProposal(proposalId);
        vm.stopPrank();

        // Vote
        deal(address(daoMockToken), user2, 5*1e18);
        vm.warp(2 days);
        vm.startPrank(user2);
        vm.expectRevert("Proposal canceled");
        daoContract.vote(proposalId, false);
        vm.stopPrank();
    }   

    function test_cancelProposal() public {
        // Create proposal
        vm.startPrank(user);
        deal(address(daoMockToken), user, 9*1e18);
        daoContract.createProposal("Proposal description", address(treasuryMock), 2*1e18, address(daoMockToken));

        // Cancel proposal
        uint256 proposalId = daoContract.proposalCount() - 1;
        daoContract.cancelProposal(proposalId);
        vm.stopPrank();

        (,,,,,,, bool canceled ,,,) = daoContract.getProposal(proposalId);

        assertTrue(canceled);
    }

    function test_cancelProposal_successIfOwner() public {
        // Create proposal
        vm.startPrank(user);
        deal(address(daoMockToken), user, 9*1e18);
        daoContract.createProposal("Proposal description", address(treasuryMock), 2*1e18, address(daoMockToken));
        vm.stopPrank();

        // Cancel proposal
        vm.startPrank(owner);
        uint256 proposalId = daoContract.proposalCount() - 1;
        daoContract.cancelProposal(proposalId);
        vm.stopPrank();

        (,,,,,,, bool canceled ,,,) = daoContract.getProposal(proposalId);

        assertTrue(canceled);
    }

    function test_cancelProposal_revertIfProposalNotDefined() public {
        // Not previously created proposal
        vm.startPrank(user);
        // Cancel proposal
        vm.expectRevert("Proposal not defined");
        daoContract.cancelProposal(1);
        vm.stopPrank();
    }

    function test_cancelProposal_revertIfProposalAlreadyCanceled() public {
        // Create proposal
        vm.startPrank(user);
        deal(address(daoMockToken), user, 9*1e18);
        daoContract.createProposal("Proposal description", address(treasuryMock), 2*1e18, address(daoMockToken));

        // Cancel proposal
        uint256 proposalId = daoContract.proposalCount() - 1;
        daoContract.cancelProposal(proposalId);
        vm.expectRevert("Proposal already canceled");
        daoContract.cancelProposal(proposalId);
        vm.stopPrank();
    }

    function test_cancelProposal_revertIfNotAuthorizedToCancel() public {
        // Create proposal
        vm.startPrank(user);
        deal(address(daoMockToken), user, 9*1e18);
        daoContract.createProposal("Proposal description", address(treasuryMock), 2*1e18, address(daoMockToken));
        vm.stopPrank();

        // Cancel proposal
        vm.startPrank(user2);
        uint256 proposalId = daoContract.proposalCount() - 1;
        vm.expectRevert("Not authorized to cancel");
        daoContract.cancelProposal(proposalId);
        vm.stopPrank();
    }

    function test_executeProposal() public {
        // Create proosal
        vm.startPrank(user);
        deal(address(daoMockToken), user, 9*1e18);
        daoContract.createProposal("Proposal description", address(treasuryMock), 2*1e18, address(daoMockToken));
        vm.stopPrank();

        // Vote
        uint256 proposalId = daoContract.proposalCount() - 1;
        deal(address(daoMockToken), user2, 11*1e18);
        vm.warp(2 days);
        vm.startPrank(user2);
        daoContract.vote(proposalId, true);
        vm.stopPrank();

        // Execute proposal
        vm.startPrank(address(daoContract));
        treasuryMock.approveProposal(proposalId);
        treasuryMock.spendFunds(proposalId, address(treasuryMock), 11*1e18, address(daoMockToken));
        vm.stopPrank();
        daoContract.executeProposal(proposalId);

        // Checks
        (,,,,,, bool executed, ,,,) = daoContract.getProposal(proposalId);

        assertTrue(executed);
    }

    function test_executeProposal_revertIfProposalNotDefined() public {
        // Create proosal
        vm.startPrank(user);
        deal(address(daoMockToken), user, 9*1e18);
        daoContract.createProposal("Proposal description", address(treasuryMock), 2*1e18, address(daoMockToken));
        vm.stopPrank();

        // Execute proposal
        uint256 proposalId = daoContract.proposalCount() - 1;
        vm.startPrank(address(daoContract));
        treasuryMock.approveProposal(proposalId);
        treasuryMock.spendFunds(proposalId, address(treasuryMock), 11*1e18, address(daoMockToken));
        vm.stopPrank();
        vm.expectRevert("Proposal not defined");
        daoContract.executeProposal(1);
    }

    function test_executeProposal_revertIfProposalAlreadyExecuted() public {
        // Create proosal
        vm.startPrank(user);
        deal(address(daoMockToken), user, 9*1e18);
        daoContract.createProposal("Proposal description", address(treasuryMock), 2*1e18, address(daoMockToken));
        vm.stopPrank();

        // Vote
        uint256 proposalId = daoContract.proposalCount() - 1;
        deal(address(daoMockToken), user2, 11*1e18);
        vm.warp(2 days);
        vm.startPrank(user2);
        daoContract.vote(proposalId, true);
        vm.stopPrank();

        // Execute proposal
        vm.startPrank(address(daoContract));
        treasuryMock.approveProposal(proposalId);
        treasuryMock.spendFunds(proposalId, address(treasuryMock), 11*1e18, address(daoMockToken));
        vm.stopPrank();
        daoContract.executeProposal(proposalId);
        vm.expectRevert("Proposal already executed");
        daoContract.executeProposal(proposalId);
    }

    function test_executeProposal_revertIfProposalCanceled() public {
        // Create proosal
        vm.startPrank(user);
        deal(address(daoMockToken), user, 9*1e18);
        daoContract.createProposal("Proposal description", address(treasuryMock), 2*1e18, address(daoMockToken));
        vm.stopPrank();

        // Vote
        uint256 proposalId = daoContract.proposalCount() - 1;
        deal(address(daoMockToken), user2, 11*1e18);
        vm.warp(2 days);
        vm.startPrank(user2);
        daoContract.vote(proposalId, true);
        vm.stopPrank();

        // Cancel proposal
        vm.prank(owner);
        daoContract.cancelProposal(proposalId);

        // Execute proposal
        vm.startPrank(address(daoContract));
        treasuryMock.approveProposal(proposalId);
        treasuryMock.spendFunds(proposalId, address(treasuryMock), 11*1e18, address(daoMockToken));
        vm.stopPrank();
        vm.expectRevert("Proposal canceled");
        daoContract.executeProposal(proposalId);
    }
    function test_executeProposal_revertIfVotingPeriodNotEnded() public {
         // Create proosal
        vm.startPrank(user);
        deal(address(daoMockToken), user, 9*1e18);
        daoContract.createProposal("Proposal description", address(treasuryMock), 2*1e18, address(daoMockToken));
        vm.stopPrank();

        // Vote
        uint256 proposalId = daoContract.proposalCount() - 1;
        deal(address(daoMockToken), user2, 11*1e18);
        vm.warp(2 days);
        vm.startPrank(user2);
        daoContract.vote(proposalId, true);
        vm.stopPrank();

        // Execute proposal
        vm.startPrank(address(daoContract));
        treasuryMock.approveProposal(proposalId);
        treasuryMock.spendFunds(proposalId, address(treasuryMock), 11*1e18, address(daoMockToken));
        vm.stopPrank();
        vm.warp(4 days);
        vm.expectRevert("Voting period not ended yet");
        daoContract.executeProposal(proposalId);
    }
    function test_executeProposal_revertIfMinimumQuorumNotReached() public {
        // Create proosal
        vm.startPrank(user);
        deal(address(daoMockToken), user, 9*1e18);
        daoContract.createProposal("Proposal description", address(treasuryMock), 2*1e18, address(daoMockToken));
        vm.stopPrank();

        // Vote
        uint256 proposalId = daoContract.proposalCount() - 1;
        deal(address(daoMockToken), user2, 9*1e18);
        vm.warp(2 days);
        vm.startPrank(user2);
        daoContract.vote(proposalId, true);
        vm.stopPrank();

        // Execute proposal
        vm.startPrank(address(daoContract));
        treasuryMock.approveProposal(proposalId);
        treasuryMock.spendFunds(proposalId, address(treasuryMock), 11*1e18, address(daoMockToken));
        vm.stopPrank();
        vm.expectRevert("Minimum quorum not reached");
        daoContract.executeProposal(proposalId);
    }
    function test_executeProposal_revertIfNotEnoughSupport() public {
        // Create proosal
        vm.startPrank(user);
        deal(address(daoMockToken), user, 9*1e18);
        daoContract.createProposal("Proposal description", address(treasuryMock), 2*1e18, address(daoMockToken));
        vm.stopPrank();

        // Vote
        uint256 proposalId = daoContract.proposalCount() - 1;
        deal(address(daoMockToken), user2, 11*1e18);
        vm.warp(2 days);
        vm.startPrank(user2);
        daoContract.vote(proposalId, false);
        vm.stopPrank();

        // Execute proposal
        vm.startPrank(address(daoContract));
        treasuryMock.approveProposal(proposalId);
        treasuryMock.spendFunds(proposalId, address(treasuryMock), 11*1e18, address(daoMockToken));
        vm.stopPrank();
        vm.expectRevert("Not enought support");
        daoContract.executeProposal(proposalId);
    }

    function test_updateConfiguration() public {
        uint256 _proposalTreshold = 4*1e18;
        uint256 _votingPeriod = 2 days; 
        uint256 _quorumVotes = 9*1e18;

        vm.startPrank(owner);
        daoContract.updateConfiguration(_proposalTreshold, _votingPeriod, _quorumVotes);
        vm.stopPrank();

        uint256 updatedProposalTreshold = daoContract.proposalTreshold();
        uint256 updatedVotingPeriod = daoContract.votingPeriod();
        uint256 updatedQuorumVotes = daoContract.quorumVotes();

        assertEq(_proposalTreshold, updatedProposalTreshold);
        assertEq(_votingPeriod, updatedVotingPeriod);
        assertEq(_quorumVotes, updatedQuorumVotes);
    }

    function test_updateConfiguration_revertIfNotOwner() public {
        vm.startPrank(user);
        vm.expectRevert();
        daoContract.updateConfiguration(3*1e18, 2 days, 5*1e18);
        vm.stopPrank();
    }

    function test_setTreasury() public {
        address _treasury = address(0x2154);
        daoContract.setTreasury(_treasury);
    }

    function test_setTreasury_revertIfInvalidAddress() public {
        address _treasury = address(0);
        vm.expectRevert("Invalid treasury address");
        daoContract.setTreasury(_treasury);
    }
}
