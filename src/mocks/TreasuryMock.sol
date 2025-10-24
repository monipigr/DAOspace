// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract TreasuryMock {

    // constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) Ownable(msg.sender) {
    //     _mint(msg.sender, initialSupply);
    // }

    // function mint(address to, uint256 amount) external onlyOwner {
    //     _mint(to, amount);
    // }

    receive() external payable {}

    function approveProposal(uint256 proposalId) external {}

    function spendFunds(uint256 proposalId, address recipient, uint256 amount, address token) external {}
}