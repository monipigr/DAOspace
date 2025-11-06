// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "../lib/forge-std/src/Test.sol";
import {StdCheats} from "../lib/forge-std/src/StdCheats.sol";
import "../src/DAOTreasury.sol";
import "../src/DAO.sol";
import "../src/mocks/GovernanceMockToken.sol";
import "../src/mocks/TreasuryMock.sol";



contract DAOTreasuryTest is Test {

    DAO public daoContract;
    DAOTreasury public treasury;
    GovernanceMockToken public daoMockToken;
    TreasuryMock public treasuryMock;

    uint256 proposalTreshold = 5*1e18;
    uint256 votingPeriod = 3 days; 
    uint256 quorumVotes = 20*1e18;

    address public owner = address(this);
    address user = vm.addr(1);

    function setUp() public {
        daoMockToken = new GovernanceMockToken("DaoToken", "DAO", 1000 * 1e18);
        treasuryMock = new TreasuryMock();

        daoContract = new DAO(address(daoMockToken), address(treasuryMock), proposalTreshold, votingPeriod, quorumVotes);
        treasury = new DAOTreasury(address(daoContract));
    }

    function test_setDAO() public view {
        address daoAddress = address(treasury.dao());

        assert(daoAddress != address(0));
    }

    function test_setDAO_revertIfInvalidDAOAddress() public {
        vm.expectRevert("Invalid DAO address");
        treasury.setDAO(address(0));
    }

    function test_setDAO_revertIfNotOwner() public {
        address newAddr = address(0x123);

        vm.prank(address(0x456));
        vm.expectRevert();
        treasury.setDAO(newAddr);
    }

    function test_fundTreasuryETH() public {
        uint256 value = 1 ether ;

        uint256 balanceBefore = address(treasury).balance;

        vm.startPrank(user);
        vm.deal(user, 2 ether);
        vm.stopPrank();

        hoax(user, value);

        treasury.fundTreasuryETH{value: value}();

        uint256 balanceAfter = address(treasury).balance;

        assertEq(balanceAfter, balanceBefore + value);
    }

    function test_fundTreasuryETH_revertIfNoETHSent() public {
        uint256 value = 0 ether ;

        vm.expectRevert("Must send ETH");
        treasury.fundTreasuryETH{value: value}();
    }

    function test_fundTreasuryToken() public {
        uint256 amount = 2*1e18;
        deal(address(daoMockToken), user, 5*1e18);

        uint256 initialBalance = daoMockToken.balanceOf(user);

        vm.startPrank(user);

        IERC20(daoMockToken).approve(address(treasury), amount);
        treasury.fundTreasuryToken(address(daoMockToken), amount);

        vm.stopPrank();

        uint256 finalBalance = daoMockToken.balanceOf(user);

        assertEq(finalBalance, initialBalance - amount);
    }

    function test_fundTreasuryToken_revertIfInvalidTokenAddress() public {
        address invalidMockAddr = address(0);
        uint256 amount = 2*1e18;

        IERC20(daoMockToken).approve(address(treasury), amount);
        vm.expectRevert("Invalid token address");
        treasury.fundTreasuryToken(address(invalidMockAddr), amount);
    }

    function test_fundTreasuryToken_revertIfAmountIs0() public {
        uint256 amount = 0;

        IERC20(daoMockToken).approve(address(treasury), amount);
        vm.expectRevert("Amount must be greater than 0");
        treasury.fundTreasuryToken(address(daoMockToken), amount);
    }

    function test_emergencyWithdraw_ETH() public {
        uint256 value = 1 ether ;

        vm.startPrank(user);
        vm.deal(user, 2 ether);
        vm.stopPrank();

        hoax(user, value);

        treasury.fundTreasuryETH{value: value}();

        vm.startPrank(owner);

        treasury.emergencyWithdraw(address(0), value, address(treasuryMock));

        vm.stopPrank();

        uint256 finalContractBalance = address(treasury).balance;

        assertEq(finalContractBalance, 0);
    }   

    function test_emergencyWithdraw_token() public {
        uint256 amount = 2*1e18;

        deal(address(daoMockToken), user, 5*1e18);

        vm.startPrank(user);

        IERC20(daoMockToken).approve(address(treasury), amount);
        treasury.fundTreasuryToken(address(daoMockToken), amount);

        vm.stopPrank();


        vm.startPrank(owner);

        treasury.emergencyWithdraw(address(daoMockToken), amount, address(treasuryMock));

        vm.stopPrank();

        uint256 finalContractBalance = daoMockToken.balanceOf(address(treasury));

        assertEq(finalContractBalance, 0);
    }

    function test_emergencyWithdraw_revertIfAmountIs0() public {
        uint256 amount = 2*1e18;

        deal(address(daoMockToken), user, 5*1e18);

        vm.startPrank(user);

        IERC20(daoMockToken).approve(address(treasury), amount);
        treasury.fundTreasuryToken(address(daoMockToken), amount);

        vm.stopPrank();


        vm.startPrank(owner);

        vm.expectRevert("Amount must be greater than 0");
        treasury.emergencyWithdraw(address(daoMockToken), 0, address(treasuryMock));

        vm.stopPrank();
    }

    function test_emergencyWithdraw_revertIfInvalidRecipientAddr() public {
        uint256 amount = 2*1e18;

        deal(address(daoMockToken), user, 5*1e18);

        vm.startPrank(user);

        IERC20(daoMockToken).approve(address(treasury), amount);
        treasury.fundTreasuryToken(address(daoMockToken), amount);

        vm.stopPrank();


        vm.startPrank(owner);

        vm.expectRevert("Invalid recipient address");
        treasury.emergencyWithdraw(address(daoMockToken), amount, address(0));

        vm.stopPrank();
    }

    function test_emergencyWithdraw_ETH_revertIfInsufficientETHBalance() public {
        uint256 value = 3 ether ;

        vm.startPrank(user);
        vm.deal(user, 2 ether);
        vm.stopPrank();

        hoax(user, value);

        treasury.fundTreasuryETH{value: value}();

        vm.startPrank(owner);

        vm.expectRevert("Insufficient ETH balance");
        treasury.emergencyWithdraw(address(0), 4 ether, address(treasuryMock));

        vm.stopPrank();
    }

    function test_emergencyWithdraw_token_revertIfInsufficientTokenBalance() public {
        uint256 amount = 2*1e18;

        deal(address(daoMockToken), user, 3*1e18);

        vm.startPrank(user);

        IERC20(daoMockToken).approve(address(treasury), amount);
        treasury.fundTreasuryToken(address(daoMockToken), amount);

        vm.stopPrank();


        vm.startPrank(owner);

        vm.expectRevert("Insufficient token balance");
        treasury.emergencyWithdraw(address(daoMockToken), 4*1e18, address(treasuryMock));

        vm.stopPrank();
    }
    
    function test_approveProposal() public {
        uint256 proposalId = 123456;

        vm.startPrank(address(daoContract));

        treasury.approveProposal(proposalId);
        bool status = treasury.approvedProposals(proposalId);

        vm.stopPrank();

        assertTrue(status);
    }

    function test_approveProposal_revertIfNotDaoContract() public {
        uint256 proposalId = 123456;

        vm.startPrank(owner);

        vm.expectRevert("Only DAO can approve proposals");
        treasury.approveProposal(proposalId);

        vm.stopPrank();
    }

    function test_approveProposal_revertIfProposalAlreadyApproved() public {
        uint256 proposalId = 123456;

        vm.startPrank(address(daoContract));

        treasury.approveProposal(proposalId);
        vm.expectRevert("Proposal already approved");
        treasury.approveProposal(proposalId);

        vm.stopPrank();
    }

    function test_spendFunds_ETH() public {
        uint256 proposalId = 123456;
        uint256 amount = 1 ether;

        // Fund treasury with eth
        vm.startPrank(user);
        vm.deal(user, 3 ether);
        vm.stopPrank();

        hoax(user, 1 ether);

        treasury.fundTreasuryETH{value: 1 ether}();

        uint256 initialETHBalance = address(treasury).balance;

        // Approve Proposal
        vm.startPrank(address(daoContract));
        treasury.approveProposal(proposalId);

        // Spend Funds
        treasury.spendFunds(proposalId, address(treasuryMock), amount, address(0));
        vm.stopPrank();

        uint256 finalETHBalance = address(treasury).balance;

        assertEq(finalETHBalance, initialETHBalance - amount);
    }

    function test_spendFunds_ETH_revertIfInsufficientETHBalance() public {
        uint256 proposalId = 123456;
        uint256 amount = 2 ether;

        // Fund treasury with eth
        vm.startPrank(user);
        vm.deal(user, 3 ether);
        vm.stopPrank();

        hoax(user, 1 ether);

        treasury.fundTreasuryETH{value: 1 ether}();

        // Approve Proposal
        vm.startPrank(address(daoContract));
        treasury.approveProposal(proposalId);

        // Spend Funds
        vm.expectRevert("Insufficient ETH balance");
        treasury.spendFunds(proposalId, address(treasuryMock), amount, address(0));
        vm.stopPrank();
    }

    function test_spendFunds_token() public {
        uint256 proposalId = 123456;
        uint256 amount = 2*1e18;

        // Fund treasury with token
        deal(address(daoMockToken), user, 5*1e18);
        vm.startPrank(user);

        IERC20(daoMockToken).approve(address(treasury), amount);
        treasury.fundTreasuryToken(address(daoMockToken), amount);

        vm.stopPrank();

        uint256 initialTokenBalance = daoMockToken.balanceOf(address(treasury));

        // Approve Proposal
        vm.startPrank(address(daoContract));
        treasury.approveProposal(proposalId);

        // Spend Funds
        treasury.spendFunds(proposalId, address(treasuryMock), amount, address(daoMockToken));
        vm.stopPrank();

        uint256 finalTokenBalance = daoMockToken.balanceOf(address(treasury));

        assertEq(finalTokenBalance, initialTokenBalance - amount);
    }

    function test_spendFunds_token_revertIfInsufficientTokenBalance() public {
        uint256 proposalId = 123456;
        uint256 amount = 2*1e18;

        // Fund treasury with token
        deal(address(daoMockToken), user, 3*1e18);
        vm.startPrank(user);

        IERC20(daoMockToken).approve(address(treasury), amount);
        treasury.fundTreasuryToken(address(daoMockToken), amount);

        vm.stopPrank();

        // Approve Proposal
        vm.startPrank(address(daoContract));
        treasury.approveProposal(proposalId);

        // Spend Funds
        vm.expectRevert("Insufficient token balance");
        treasury.spendFunds(proposalId, address(treasuryMock), 4*1e18, address(daoMockToken));
        vm.stopPrank();
    }

    function test_spendFunds_revertIfInvalidRecipient() public {
        uint256 proposalId = 123456;
        uint256 amount = 2*1e18;
        address recipient = address(0);
        address token = address(daoMockToken);

        // Fund treasury with token
        deal(address(daoMockToken), user, 5*1e18);
        vm.startPrank(user);

        IERC20(daoMockToken).approve(address(treasury), amount);
        treasury.fundTreasuryToken(address(daoMockToken), amount);

        vm.stopPrank();

        // Approve Proposal
        vm.startPrank(address(daoContract));
        treasury.approveProposal(proposalId);

        // Spend Funds
        vm.expectRevert("Invalid recipient");
        treasury.spendFunds(proposalId, recipient, amount, token);
        vm.stopPrank();
    }

    function test_spendFunds_revertIfAmountIs0() public {
        uint256 proposalId = 123456;
        uint256 amount = 2*1e18;
        address recipient = address(treasuryMock);
        address token = address(daoMockToken);

        // Fund treasury with token
        deal(address(daoMockToken), user, 5*1e18);
        vm.startPrank(user);

        IERC20(daoMockToken).approve(address(treasury), amount);
        treasury.fundTreasuryToken(address(daoMockToken), amount);

        vm.stopPrank();

        // Approve Proposal
        vm.startPrank(address(daoContract));
        treasury.approveProposal(proposalId);

        // Spend Funds
        vm.expectRevert("Amount must be greater than 0");
        treasury.spendFunds(proposalId, recipient, 0, token);
        vm.stopPrank();
    }

    function test_spendFunds_revertIfProposalNotApproved() public {
        uint256 proposalId = 123456;
        uint256 amount = 2*1e18;
        address recipient = address(treasuryMock);
        address token = address(daoMockToken);

        // Fund treasury with token
        deal(address(daoMockToken), user, 5*1e18);
        vm.startPrank(user);

        IERC20(daoMockToken).approve(address(treasury), amount);
        treasury.fundTreasuryToken(address(daoMockToken), amount);

        vm.stopPrank();

        // Approve Proposal
        vm.startPrank(address(daoContract));
        vm.expectRevert("Proposal must be approved");
        // treasury.approveProposal(proposalId);

        // Spend Funds
        treasury.spendFunds(proposalId, recipient, amount, token);
        vm.stopPrank();
    }

    function test_spendFunds_revertIfProposalAlreadyExecuted() public {
        uint256 proposalId = 123456;
        uint256 amount = 2*1e18;
        address recipient = address(treasuryMock);
        address token = address(daoMockToken);

        // Fund treasury with token
        deal(address(daoMockToken), user, 5*1e18);
        vm.startPrank(user);

        IERC20(daoMockToken).approve(address(treasury), amount);
        treasury.fundTreasuryToken(address(daoMockToken), amount);

        vm.stopPrank();

        // Approve Proposal
        vm.startPrank(address(daoContract));
        treasury.approveProposal(proposalId);

        // Spend Funds
        treasury.spendFunds(proposalId, recipient, amount, token);
        vm.expectRevert("Proposal already executed");
        treasury.spendFunds(proposalId, recipient, amount, token);
        vm.stopPrank();
    }

    function test_spendFunds_revertIfSenderIsNotDaoContract() public {
        uint256 proposalId = 123456;
        uint256 amount = 2*1e18;
        address recipient = address(treasuryMock);
        address token = address(daoMockToken);

        // Fund treasury with token
        deal(address(daoMockToken), user, 5*1e18);
        vm.startPrank(user);

        IERC20(daoMockToken).approve(address(treasury), amount);
        treasury.fundTreasuryToken(address(daoMockToken), amount);

        vm.stopPrank();

        // Approve Proposal
        vm.startPrank(address(daoContract));
        treasury.approveProposal(proposalId);
        vm.stopPrank();

        // Spend Funds
        vm.startPrank(user);
        vm.expectRevert("Only DAO can send funds");
        treasury.spendFunds(proposalId, recipient, amount, token);
        vm.stopPrank();
    }

    function test_receive() public {
        uint256 value = 1 ether ;

        uint256 balanceBefore = address(treasury).balance;

        vm.startPrank(user);
        vm.deal(user, 2 ether);
        vm.stopPrank();

        hoax(user, value);

        (bool success, ) = address(treasury).call{value: value}("");
        require(success, "Transfer failed");

        uint256 balanceAfter = address(treasury).balance;

        assertEq(balanceAfter, balanceBefore + value);
    }
}