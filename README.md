# Dao base

A decentralized autonomous organization (DAO) that enables community-driven decision making and fund allocation. DAOSpace allows users to create proposals, vote on them using governance tokens, and execute approved proposals to spend treasury funds. The modular design separates concerns between the DAO, Treasury, and Governance Token contracts. Built with Solidity and Foundry, with a complete testing suite.

### 🤔 What is a DAO on DeFi?

A DAO, or Decentralized Autonomous Organization, is a community governed by a set of predefined rules encoded in smart contracts on a blockchain. It operates without relying on a central authority, allowing members to participate in decision-making processes through their assigned voting power.
In a DAO, the voting power of each member is determined by the number of governance tokens they hold in their wallet. When a decision needs to be made, a proposal is created, and members vote on it. In this case, the impact of each vote is proportional to the member's voting power. Once the voting period ends, the outcome is automatically executed according to the rules defined in the smart contracts.
A DAO is built on three fundamental pillars:

**Treasury**: The treasury is where the organization's funds are stored during the proposal process. When a proposal is approved, the allocated funds are automatically transferred to their intended destination based on the predefined rules in the smart contract.
**Governance Token**: Each DAO typically has its own governance token, which serves as a representation of voting power. In most cases, the more tokens a member holds, the greater their influence on the organization's decisions.
**DAO Core**: The core of the DAO is where the main logic resides. It defines the rules for creating proposals, voting mechanisms, executing approved proposals, and other customizable aspects of the organization's functioning.

A DAO aims for Decentralized Autonomous Organization.
This is like a community organized within an internal predefined rules written in smarts contracts.
Every person on the DAO can participate in the decision making process through their voting power asigned.
The voting power is determined by the number of token the user has on their wallet.
For example, there's a decisions to be taken for the community. A proposal is created. The user votes for the proposal. Depending on their voting power, their vote will have more impact.
When the voting time is ended, automaticly the funds allocatted for that proposal are transfer according to the predefined contract rules.
A DAO is based on 3 pilars:

- **Treasury**: Where the funds are stored during the proposal time. When proposal time is ended, funds are transfered to their destination according to the proposal rules.
- **Governance token**: Usually each DAO has each gobernance token. This is serves as voting power. Normally as much tokens stored more voting power you have.
- **DAO Core**: Where the core dao logic occurs. Each dao can define their rules for creating the proposals, voting rules, execute proposals and other customizable rules

Some well-known examples of successful DAOs in the blockchain space include:

**[MakerDAO](https://makerdao.com)**: The creators of DAI, one of the most widely used stablecoins alongside USDT and USDC.
**[Compound](https://compound.finance/)**: A popular lending and borrowing protocol in the DeFi ecosystem.

┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────────┐
│ Treasury │ │ Governance Token │ │ DAO Core │
│ │ │ │ │ │
│ Funds: 1000 ETH │ │ Total Supply: 100000 │ │ Proposal Creation │
│ │ │ Member A: 50000 │ │ Voting Mechanism │
│ Proposal Funding │ │ Member B: 30000 │ │ Proposal Execution │
│ │ │ Member C: 20000 │ │ │
│ Approved Proposals │ │ │ │ Proposal States: │
│ ✅ Proposal 1 │ │ Voting Power: │ │ 📝 Created │
│ Funds: 500 ETH │ │ Member A: 50% │ │ 🗳️ Voting Period │
│ ✅ Proposal 2 │ │ Member B: 30% │ │ ✅ Approved │
│ Funds: 300 ETH │ │ Member C: 20% │ │ ❌ Rejected │
│ │ │ │ │ 💰 Executed │
└──────────────────────┘ └──────────────────────┘ └──────────────────────┘
▲ ▲ ▲
│ │ │
│ Approved Proposals │ │
└──────────────────────────► │ │
│ Proposal Voting │
│ ◄────────────────────────┘
│
│ Execution Request
└─────────────────────────────►

## ✨ Features

- 🗳️ **Delegation/Undelegation Option**: Users can delegate their votes to another user. Only one delegation per user. `delegateVotingPower()`and `undelegateVotingPower()`
- 🧩 **Modular DAO**: Treasury is adjusted to different DAOs using `setDAO()`
- 💰 **Fund Treasury**: Treasury contract is ready to receive both ERC20 tokens and Ether. `fundTreasuryETH()`and `fundTreasuryWithToken()`
- ✅ **Approve Proposal**: Proposals can be approved by the DAO contract using `approveProposal()`
- 💸 **Spend Funds**: Approved proposals can spend funds from the treasury using `spendFunds()`
- 📝 **Create Proposal**: Anyone with a minimum voting power can create a new proposal using `createProposal()`
- 🗳️ **Vote**: Everyone can vote on a proposal. Voting power determines the weight of the vote. `vote()`
- ❌ **Cancel Proposal**: Proposals can be canceled only by the owner or the creator of that proposal using `cancelProposal()`
- ⚙️ **Execute Proposal**: Proposals are executed when the voting period has ended and the proposal has reached the minimum quorum and minimum support. `executeProposal()`
- 🚨 **Emergency Withdrawal**: Owner can rescue stuck tokens if needed using `emergencyWithdraw()`

## 🧩 Smart Contract Architecture and Security Patterns

### Design and Architecture Patterns

- **Scalability**: (or upgradeability) pattern for the scalability of protocols where the treasury is adjusted modularly to different DAO contracts. Smart contract actualization without having to change the Treasury contract.
- **Modular Separate Concerns**: Each contract has a specific function, following the design principle of a single responsibility for each contract.
- **CEI Pattern**: All external functions follow the Checks-Effects-Interactions pattern to minimize vulnerabilities.

### Security Measures

- **🔑 Access Restriction**: `onlyOwner` modifier restricts access to important functions like `setDAO` for critical vulnerabilities and prevention attacks.
- 🪙 **SafeERC20**: All token transfers use `SafeERC20` to handle non-standard ERC20 implementations safely.
- 🛡️ **Reentrancy Protection**: Critical functions (`execute`, `setTreasury`, `spendFunds`, `emergencyWithdraw`) are protected with OpenZeppelin's `ReentrancyGuard`.
- 📢 **Event Logging**: All state mutations emit events for transparency and off-chain monitoring, such as `FundSpent`, `ProposalApproved`, `ProposalCreated`, `Voted`, and more.
- 🧪 **Testing**: Complete testing suite with +98% coverage.

## 🧪 Tests

Complete testing suite using **Foundry**, achieving +98% code coverage across all contracts.
The suite includes happy paths, negative paths, and edge cases to ensure robustness.

### Coverage Results:

```bash
Ran 3 test suites in 227.03ms (54.18ms CPU time): 70 tests passed, 0 failed, 0 skipped (70 total tests)

╭-----------------------------------+------------------+------------------+-----------------+-----------------╮
| File                              | % Lines          | % Statements     | % Branches      | % Funcs         |
+=============================================================================================================+
| src/DAO.sol                       | 100.00% (73/73)  | 100.00% (64/64)  | 95.65% (44/46)  | 100.00% (9/9)   |
|-----------------------------------+------------------+------------------+-----------------+-----------------|
| src/DAOGovernanceToken.sol        | 100.00% (28/28)  | 100.00% (23/23)  | 100.00% (15/15) | 100.00% (6/6)   |
|-----------------------------------+------------------+------------------+-----------------+-----------------|
| src/DAOTreasury.sol               | 95.45% (42/44)   | 94.74% (36/38)   | 92.86% (39/42)  | 100.00% (8/8)   |
|-----------------------------------+------------------+------------------+-----------------+-----------------|
| src/mocks/GovernanceMockToken.sol | 100.00% (4/4)    | 100.00% (3/3)    | 100.00% (0/0)   | 100.00% (2/2)   |
|-----------------------------------+------------------+------------------+-----------------+-----------------|
| src/mocks/TreasuryMock.sol        | 100.00% (2/2)    | 100.00% (0/0)    | 100.00% (0/0)   | 100.00% (2/2)   |
|-----------------------------------+------------------+------------------+-----------------+-----------------|
| Total                             | 98.68% (149/151) | 98.44% (126/128) | 95.15% (98/103) | 100.00% (27/27) |
╰-----------------------------------+------------------+------------------+-----------------+-----------------╯
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test
forge test -vvvv --match-test test_createProposal

# Check coverage
forge coverage
```

## 🧠 Technologies Used

- ⚙️ **Solidity** (`^0.8.24`) – smart contract programming language
- 🧪 **Foundry** – framework for development, testing, fuzzing, invariants and deployment
- 📚 **OpenZeppelin Contracts** – `ERC20`, `Ownable`, `ReentrancyGuard`, `SafeERC20`
- 🛠️ **MockToken** – custom ERC20 token implementation for testing

## 📜 License

This project is licensed under the MIT License.
