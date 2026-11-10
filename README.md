# Solidity Smart Contract Assignment

**Name : Lê Đức Bảo**

**Roll No: 1**

**Email : [leducbao282@gmail.com](mailto:leducbao282@gmail.com)**




| # | Contract | Level | Tested on Ganache | Screenshots |
|---|---|---|---|---|
| 01 | [Storage](contracts/01_Storage.sol) | Basic | YES (automated Ganache checks) | 01_compile.png, 01_test2.png (pending) |
| 02 | [Greeting](contracts/02_Greeting.sol) | Basic | YES (automated suite) | 02_compile.png, 02_test2.png (pending) |
| 03 | [Counter](contracts/03_Counter.sol) | Basic | YES (automated suite) | 03_compile.png, 03_test2.png (pending) |
| 04 | [Ownable](contracts/04_Ownable.sol) | Basic | YES (automated suite) | 04_compile.png, 04_test2.png (pending) |
| 05 | [SimpleBank](contracts/05_SimpleBank.sol) | Intermediate | YES (automated suite) | 05_compile.png, 05_test2.png (pending) |
| 06 | [Voting](contracts/06_Voting.sol) | Intermediate | YES (automated suite) | 06_compile.png, 06_test2.png (pending) |
| 07 | [MyToken](contracts/07_MyToken.sol) | Intermediate | YES (automated suite) | 07_compile.png, 07_test2.png (pending) |
| 08 | [Crowdfunding](contracts/08_Crowdfunding.sol) | Intermediate | YES (automated suite) | 08_compile.png, 08_test2.png (pending) |
| 09 | [Lottery](contracts/09_Lottery.sol) | Advanced | YES (automated suite) | 09_compile.png, 09_test2.png (pending) |
| 10 | [TimeLockVault](contracts/10_TimeLockVault.sol) | Advanced | YES (automated suite) | 10_compile.png, 10_test2.png (pending) |
| 11 | [Escrow](contracts/11_Escrow.sol) | Advanced | YES (automated suite) | 11_compile.png, 11_test2.png (pending) |
| 12 | [SimpleNFT](contracts/12_SimpleNFT.sol) | Advanced | YES (automated suite) | 12_compile.png, 12_test2.png (pending) |
| 13 | [EnglishAuction](contracts/13_EnglishAuction.sol) | Advanced | YES (automated suite) | 13_compile.png, 13_test2.png (pending) |
| 14 | [MultisigWallet](contracts/14_MultisigWallet.sol) | Advanced | YES (automated suite) | 14_compile.png, 14_test2.png (pending) |
| 15 | [StakingRewards](contracts/15_StakingRewards.sol) | Advanced | YES (automated suite) | 15_compile.png, 15_test2.png (pending) |

All 15 assignment contracts are implemented. Automated tests cover success and failure paths on Hardhat and Ganache. Levels are suggested assignment categories.
All 30 actual screenshots remain pending; see [the checklist](screenshots/README.md).

## How to run

1. Open Remix, paste the contract, and compile with a compatible Solidity `0.8.x` version (`0.8.28` for the included Counter). Select the Paris EVM target for this Ganache setup.
2. Start Ganache QUICKSTART on `http://127.0.0.1:7545` with chain ID `1337`.
3. In Remix, select **Environment = Custom External Http Provider** and enter `http://127.0.0.1:7545`.
4. Deploy and test per the checklist in each assignment contract file. For the included Counter example, verify that `count` starts at `0`, call `increment`, and verify that `count` becomes `1`.

## Structure

- `contracts/`: Solidity contracts.
- `scripts/`: Deployment and utility scripts.
- `test/`: Contract tests.
- `screenshots/`: Actual compilation and test screenshots (minimum 30).

## Solidity environment

Uses Hardhat 2, ethers 6, Solidity 0.8.28 and Ganache. Install dependencies:

```sh
npm ci
npm run compile
npm test
```

## Connect to Ganache

Start Ganache Desktop with RPC `http://127.0.0.1:7545` and chain ID `1337`.
Alternatively, when that port is free, run the bundled CLI in a separate terminal:

```sh
npm run ganache
```

The CLI stores its local blockchain in the ignored `.ganache/` directory.
Use only local development accounts. Hardhat uses Ganache's unlocked accounts;
no private key or `.env` file is required.

Verify the connection and deploy the example:

```sh
npm run check:ganache
npm run deploy:ganache
```

Deployment verifies bytecode, sends an increment transaction, and checks that
`count` becomes `1`. Each deployment creates a new Counter instance. The compiler
targets Paris for Ganache compatibility. `npm test` uses Hardhat's isolated test
network. Counter is included as assignment 03.

## Dependency audit

At setup, `npm install` reported 50 dependency vulnerabilities (10 low,
7 moderate, 28 high, 5 critical). These are unresolved; inspect `npm audit`
before extending this environment beyond local development. Do not apply
`npm audit fix --force` blindly, as it can change major versions.
## Run Storage

```sh
npx hardhat test test/Storage.js
npm run deploy:storage
```

Storage allows any account to overwrite its value using `store(uint256)`.
Read it with `retrieve()`. The deployment script deploys a fresh instance and
verifies initial zero, writes, overwrites, zero, the uint256 maximum, and a
second account write on Ganache. Its final value is `7`. Actual screenshots
remain pending.

## Run all assignment tests

```sh
npm test
npm run test:ganache
```

Ganache must be running on port 7545 with chain ID 1337. The full suite uses
`evm_snapshot`, `evm_increaseTime`, and `evm_revert` for deadline tests and restores
the snapshot afterward. Run it on an idle local Ganache instance: concurrent
transactions would also be rolled back. Test deployments are temporary.
`contracts/test/BankProbe.sol` is an adversarial test helper, not an assignment.

## Constructor inputs and manual checks

Amounts are in wei or smallest token units. Duration values are seconds.
One whole MyToken is `10**18` units; its constructor does not scale supply.
Use the checklist comments inside each file and these starting inputs in Remix.

| # | Constructor inputs | Manual check |
|---|---|---|
| 01 | None | store(42), retrieve() = 42 |
| 02 | `"Hello"` | setGreeting, read greeting |
| 03 | None | increment, decrement, reset; cap = 100 |
| 04 | None | Deploy ProtectedVault; deposit; owner withdraw; transferOwnership |
| 05 | None | deposit with ETH, withdraw; verify per-user balances |
| 06 | `["A","B"]` | Chairperson authorize voter; vote once; winnerName |
| 07 | `"VikToken","VKT",1000000` | transfer; approve; transferFrom as spender |
| 08 | `1000000000000000000,60` | contribute; after deadline claimFunds or refund |
| 09 | `10000000000000000,2` | Two non-manager entries; manager pickWinner |
| 10 | `beneficiaryAddress,60` | deposit; extendLock as beneficiary; withdraw after unlock |
| 11 | `sellerAddress,arbiterAddress` with ETH value | Buyer confirmDelivery or raiseDispute; arbiter resolve |
| 12 | `"My NFT","MNFT"` | Minter mint(to,uri); IDs start at 1; approve; transferFrom |
| 13 | `nftAddress,1,10000000000000000,60` | Seller approve NFT, start; others bid; end; withdraw credits |
| 14 | `[ownerA,ownerB,ownerC],2` | Fund wallet; submitTransaction(to,wei,"0x"); two confirms; execute |
| 15 | `stakingTokenAddress,rewardTokenAddress` | Two different MyTokens; approve allowances; fundRewards; stake; claimReward; withdraw |

## Learning scope and limitations

These are educational implementations, not audited deployments for real funds.
Voting has chairperson authorization and no closing time; ties choose the first
candidate. Ownable uses immediate ownership transfer. Lottery deliberately uses
the assignment's predictable/manipulable blockhash selection, trusts the manager
to draw, and can stall if the selected recipient rejects ETH. Escrow requires
three distinct parties and a positive payment at deployment; its AwaitingPayment
enum value is unused, and payouts revert if the recipient rejects ETH. There is
no automatic dispute timeout. Auction escrows an NFT using transferFrom and
returns outbid funds and seller proceeds through withdraw; bidders that are
contracts must be able to manage an NFT received without a receiver callback.

Staking supports standard, bool-returning tokens such as MyToken, not rebasing
or fee-on-transfer tokens. It uses distinct staking/reward tokens and fresh
funding for each reward period. A new period can start only after the previous
one ends. Rounding dust and rewards scheduled while nobody stakes stay in the
contract; there is no administrator recovery function. Reward rates and amounts
should be reasonable to avoid uint256 arithmetic overflow. Tests establish the
listed behavior, not formal verification or standards certification.

Implementation references: [Solidity security considerations](https://docs.soliditylang.org/en/latest/security-considerations.html),
[ERC-20](https://eips.ethereum.org/EIPS/eip-20),
[ERC-721](https://eips.ethereum.org/EIPS/eip-721).
Actual screenshots must still be captured in Remix/Ganache; no synthetic evidence
images have been generated.
