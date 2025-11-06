// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title DAOGovernanceToken
 * @dev ERC20 token used for DAO governance voting
 * This token represents voting power in the DAO
 */
contract DAOGovernanceToken is ERC20, Ownable {

    // Mapping to track if an address has been delegated voting power
    mapping(address => bool) public hasDelegated;

    // Mapping to track delegation of voting power
    mapping(address => address) public delegates;
    
    // Mapping to track delegated voting power
    mapping(address => uint256) public delegatedVotes;

    event VotingPowerDelegated(address indexed delegator, address indexed delegate, uint256 amount);
    event VotingPowerUndelegate(address indexed delegator, address indexed delegate, uint256 amount);

    /**
     * @dev Constructor that gives msg.sender all of initial tokens
     * @param name Token name
     * @param symbol Token symbol
     * @param initialSupply Initial token supply
     */
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Delegate voting power to another address
     * @param delegate Address to delegate voting power to
     * @param amount Amount of tokens to delegate
     */
    function delegateVotingPower(address delegate, uint256 amount) external {
        require(delegate != address(0), "Delegate does not exist");
        require(amount > 0, "Amount must be greater than 0");
        require(delegate != msg.sender, "Cannot delegete to self");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        _transfer(msg.sender, delegate, amount);

        delegatedVotes[delegate] += amount; //JMCruz aquí pone += pero entonces si hubiera ya un amount, lo cual entiendo que sería tecnicamente imposible porque solo se puede delegar una vez, se sobreescribiría
        hasDelegated[msg.sender] = true;
        delegates[msg.sender] = delegate;

        emit VotingPowerDelegated(msg.sender, delegate, amount);
    }

    /**
     * @dev Undelegate voting power from delegate
     * @param amount Amount of tokens to undelegate
     */
    function undelegateVotingPower(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(hasDelegated[msg.sender], "Delegate first your votes");
        require(delegatedVotes[delegates[msg.sender]] >= amount, "Insufficient delegated power");
        
        _transfer(delegates[msg.sender], msg.sender, amount);

        delegatedVotes[delegates[msg.sender]] -= amount;
        if (delegatedVotes[delegates[msg.sender]] == 0) {
            hasDelegated[msg.sender] = false;
            delete delegates[msg.sender];
        }

        emit VotingPowerUndelegate(msg.sender, delegates[msg.sender], amount);
    }

    /**
     * @dev Get the voting power of an address (including delegated votes)
     * @param account Address to check voting power for
     * @return Total voting power
     */
    function getVotingPower(address account) external view returns (uint256) {
        return balanceOf(account);
    }

    /**
     * @dev Mint new tokens (only owner)
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    /**
     * @dev Burn tokens from caller
     * @param amount Amount of tokens to burn
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

}

