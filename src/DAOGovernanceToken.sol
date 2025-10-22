// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/*
FEATURES: 
 */

contract DAOGovernanceToken is ERC20, Ownable {

    mapping(address => bool) public hasDelegated; 
    mapping(address => address) public delegates;
    mapping(address => uint256) public delegatedVotes;

    event VotingPowerDelegated(address indexed delegator, address indexed delegate, uint256 amount);
    event VotingPowerUndelegate(address indexed delegator, address indexed delegate, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    function getVotingPower(address account) external view returns(uint256) {
        return balanceOf(account);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function delegateVotingPower(address delegate, uint256 amount) external {
        //Comprueba que la address del delegate no sea 0
        require(delegate != address(0), "Delegate does not exist");
        //Comprueba que el amount no sea 0
        require(amount > 0, "Amount must be greater than 0");
        // Faltará comprobar que no te estás transfiriendo a ti mismo
        require(delegate != msg.sender, "Cannot delegete to self");
        // Faltará comprobar que tienes suficiente amount para transferir votos
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        _transfer(msg.sender, delegate, amount);

        //delegamos los votos propiamente con el mapping de delegateVotes[delegate] += amount
        delegatedVotes[delegate] += amount; //JMCruz aquí pone += pero entonces si hubiera ya un amount, lo cual entiendo que sería tecnicamente imposible porque solo se puede delegar una vez, se sobreescribiría
        //actualizamos también el hasdelegated a true
        hasDelegated[msg.sender] = true;
        //actualizamos también el delegates del msg sender al delegate
        delegates[msg.sender] = delegate;

        //emitimos evento
        emit VotingPowerDelegated(msg.sender, delegate, amount);
    }
    
    function undelegateVotingPower(uint256 amount) external {
        // Comprobaciones
        // Que el amount no es 0
        require(amount > 0, "Amount must be greater than 0");
        // que la persona que está llamando a la funcion ha delegado anteriormente
        require(hasDelegated[msg.sender], "Delegate first your votes");
        //que la cantidad de votos que estamos quitando es menor o igual a la que hemos delegado anteriomente
        require(delegatedVotes[delegates[msg.sender]] >= amount, "Insufficient delegated power");

        
        // Trasnfer back
        _transfer(delegates[msg.sender], msg.sender, amount);

        // Actualizamos variables
        delegatedVotes[delegates[msg.sender]] -= amount;
        if (delegatedVotes[delegates[msg.sender]] == 0) {
            hasDelegated[msg.sender] = false;
            delete delegates[msg.sender];
        }

        // emit event
        emit VotingPowerUndelegate(msg.sender, delegates[msg.sender], amount);
    }

}

