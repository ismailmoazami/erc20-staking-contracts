# ERC20 Staking
A simple ERC20 staking smart contract built with Solidity + Foundry framework.
Users can deposit an ERC20 token, earn yield over time, claim rewards, and withdraw their tokens.

## Features
- Stake any ERC20 token (set at deployment)
- Claim rewards based on staking duration and reward rate
- Withdraw full or partial staked amount
- Owner can update the annual reward rate
- Uses OpenZeppelin's Ownable, ReentrancyGuard, and IERC20

## How it works
- When a user calls deposit, their tokens are transferred to the contract and a StakeInfo is stored.
- Rewards are calculated linearly over time based on the REWARD_RATE_PER_YEAR.
- Rewards must be manually claimed using claimRewards().
- Users can withdraw partial or full amount using withdraw().

## Install
Make sure you have Foundry installed: https://book.getfoundry.sh/getting-started/installation
```bash
git clone https://github.com/your-username/erc20-staking
cd erc20-staking
forge install
```

## Test
```bash
forge test
```

## Deploy 
```bash
forge script script/Deploy.s.sol --broadcast --rpc-url $SEPOLIA_RPC_URL --account your_account
# Use encrypted accounts in foundry for safety!
```

