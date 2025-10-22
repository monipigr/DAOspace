// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import "../src/DAOGovernanceToken.sol";


contract DAOGovernanceTest is Test {

    DAOGovernanceToken public daoToken;

    address public owner = address(this);
    address public user = vm.addr(1);
    address public user2 = vm.addr(2);

    function setUp() public {
        daoToken = new DAOGovernanceToken("DaoToken", "DAO", 1000 * 1e18);
    }

    function test_getVotingPower() public {
        vm.startPrank(user);
        uint256 userBalanceBefore = daoToken.balanceOf(user);   
        deal(address(daoToken), user, 100*1e18);

        uint256 userBalanceAfter = daoToken.getVotingPower(user);

        assertEq(userBalanceAfter, userBalanceBefore + 100*1e18);   
        vm.stopPrank();
    }

    function test_mint() public {
        vm.startPrank(owner);
        uint256 userBalanceBefore = daoToken.balanceOf(user);   

        daoToken.mint(user, 100*1e18);
        uint256 userBalanceAfter = daoToken.balanceOf(user);  
        assertEq(userBalanceAfter, userBalanceBefore + 100*1e18);   
        vm.stopPrank();
    }

    function test_mint_revertIfNotOwner() public {
        vm.startPrank(user);

        vm.expectRevert();
        daoToken.mint(user, 100*1e18);
    }

    function test_burn() public {
        vm.startPrank(user);

        deal(address(daoToken), user, 100*1e18);
        daoToken.burn(100*1e18);
        uint256 userAmountAfter = daoToken.balanceOf(user);

        vm.assertEq(userAmountAfter, 0);
        vm.stopPrank();
    }

    function test_delegateVotingPower() public {
        uint256 amount = 5*1e18;
        address delegate = user2;
        deal(address(daoToken), user, amount);
        uint256 userBalanceBefore = daoToken.balanceOf(user);
        uint256 user2BalanceBefore = daoToken.balanceOf(user2);

        vm.startPrank(user);

        daoToken.delegateVotingPower(delegate, amount);

        vm.stopPrank();

        uint256 userBalanceAfter = daoToken.balanceOf(user);
        uint256 user2BalanceAfter = daoToken.balanceOf(user2);

        assertEq(userBalanceBefore, user2BalanceAfter);
        assertEq(user2BalanceBefore, userBalanceAfter);
        assert(daoToken.delegatedVotes(delegate) == amount);
        assert(daoToken.hasDelegated(user) == true);
        assert(daoToken.delegates(user) == address(delegate));
    }

    function test_delegateVotingPower_revertIfDelegateIsNotValid() public {
        uint256 amount = 5*1e18;
        address delegate = address(0);

        vm.startPrank(user);

        vm.expectRevert("Delegate does not exist");
        daoToken.delegateVotingPower(delegate, amount);

        vm.stopPrank();
    }

    function test_delegateVotingPower_revertIfAmountIs0() public {
        uint256 amount = 0;
        address delegate = user2;

        vm.startPrank(user);

        vm.expectRevert("Amount must be greater than 0");
        daoToken.delegateVotingPower(delegate, amount);

        vm.stopPrank();
    }

    function test_delegateVotingPower_revertIfDelegateToSelf() public {
        uint256 amount = 5*1e18;
        address delegate = user;
        deal(address(daoToken), user, amount);

        vm.startPrank(user);

        vm.expectRevert("Cannot delegete to self");
        daoToken.delegateVotingPower(delegate, amount);

        vm.stopPrank();
    }

    function test_delegateVotingPower_revertIfInsufficientBalance() public {
        uint256 amount = 5*1e18;
        address delegate = user2;
        deal(address(daoToken), user, amount);

        vm.startPrank(user);

        vm.expectRevert("Insufficient balance");
        daoToken.delegateVotingPower(delegate, 6*1e18);

        vm.stopPrank();
    }

    function test_undelegateVotingPower() public {
        uint256 delegatedAmount = 2*1e18;
        address delegate = user2;
        deal(address(daoToken), user, 8*1e18);
        uint256 userBalanceBefore = daoToken.balanceOf(user); // 8
        uint256 user2BalanceBefore = daoToken.balanceOf(user); // 8

        vm.startPrank(user);

        daoToken.delegateVotingPower(delegate, delegatedAmount); // user = 8-2 = 6
        daoToken.undelegateVotingPower(delegatedAmount); //tiene 6, quiere recuperar 1

        vm.stopPrank();

        uint256 userBalanceAfter = daoToken.balanceOf(user);
        uint256 user2BalanceAfter = daoToken.balanceOf(user);

        assertEq(userBalanceBefore, userBalanceAfter);
        assertEq(user2BalanceBefore, user2BalanceAfter);
        assert(daoToken.delegatedVotes(delegate) == 0);
        assert(daoToken.hasDelegated(user) == false);
        assert(daoToken.delegates(user) == address(0));
    }

    /// Ensures if undelegate is not about all the amount
    function test_undelegateVotingPower_someVotingPower() public {
        uint256 delegatedAmount = 2*1e18;
        uint256 undelegatedAmount = 1*1e18;
        address delegate = user2;
        deal(address(daoToken), user, 8*1e18);
        uint256 userBalanceBefore = daoToken.balanceOf(user); // 8
        uint256 user2BalanceBefore = daoToken.balanceOf(user); // 8

        vm.startPrank(user);

        daoToken.delegateVotingPower(delegate, delegatedAmount); // user = 8-2 = 6
        daoToken.undelegateVotingPower(undelegatedAmount); //tiene 6, quiere recuperar 1

        vm.stopPrank();

        uint256 userBalanceAfter = daoToken.balanceOf(user);
        uint256 user2BalanceAfter = daoToken.balanceOf(user);

        assertEq(userBalanceBefore, userBalanceAfter + undelegatedAmount);
        assertEq(user2BalanceBefore, user2BalanceAfter + undelegatedAmount);
        assert(daoToken.delegatedVotes(delegate) == delegatedAmount - undelegatedAmount);
        assert(daoToken.hasDelegated(user) == true);
        assert(daoToken.delegates(user) == address(delegate));
    }



    function test_undelegateVotingPower_revertIfAmountIs0() public {
        uint256 delegatedAmount = 2*1e18;
        uint256 undelegatedAmount = 0;
        address delegate = user2;
        deal(address(daoToken), user, 8*1e18);
        
        vm.startPrank(user);

        daoToken.delegateVotingPower(delegate, delegatedAmount); 
        vm.expectRevert("Amount must be greater than 0");
        daoToken.undelegateVotingPower(undelegatedAmount);

        vm.stopPrank();   
    }

    function test_undelegateVotingPower_revertIfNotDelegatedFirst() public {
        // uint256 delegatedAmount = 2*1e18;
        uint256 undelegatedAmount = 2*1e18;
        // address delegate = user2;
        deal(address(daoToken), user, 8*1e18);
        
        vm.startPrank(user);

        vm.expectRevert("Delegate first your votes");
        daoToken.undelegateVotingPower(undelegatedAmount);

        vm.stopPrank();   
    }

    function test_undelegateVotingPower_revertIfInsufficientDelegatedPower() public {
        uint256 delegatedAmount = 2*1e18;
        uint256 undelegatedAmount = 3*1e18;
        address delegate = user2;
        deal(address(daoToken), user, 8*1e18);
        
        vm.startPrank(user);

        daoToken.delegateVotingPower(delegate, delegatedAmount); 
        vm.expectRevert("Insufficient delegated power");
        daoToken.undelegateVotingPower(undelegatedAmount);

        vm.stopPrank();   
    }
}