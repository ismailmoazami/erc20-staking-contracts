// SPDX-License-Identifier: MIT 
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { ERC20Staking } from "src/ERC20Staking.sol";
import { ERC20Mock } from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract ERC20StakingTest is Test {
    
    ERC20Staking stakingContract;
    ERC20Mock token;

    address user1 = makeAddr("user1");

    uint256 constant STAKE_AMOUNT = 10e18;
    uint256 constant TEN_DAYS_IN_SECOND = 10 days;

    function setUp() external {
        token = new ERC20Mock();
        stakingContract = new ERC20Staking(address(token));

        // minting some tokens
        uint256 amount = 500e18; 
        token.mint(user1, amount);
        // minting tokens for staking contract for rewards
        token.mint(address(stakingContract), amount);
    }

    function test_staking() external {
        vm.startPrank(user1);
        
        token.approve(address(stakingContract), STAKE_AMOUNT);
        stakingContract.deposit(STAKE_AMOUNT);

        vm.stopPrank();
        uint256 stakedAmountInContract = stakingContract.getUserTotalStaked(user1);
        assertEq(stakedAmountInContract, STAKE_AMOUNT);
    }

    function test_can_stake_many_times() external {
        vm.startPrank(user1);
        token.approve(address(stakingContract), STAKE_AMOUNT * 10);
        for(uint256 i = 0; i < 10; i++) {
            stakingContract.deposit(STAKE_AMOUNT);
        }

        vm.stopPrank();
        uint256 stakedAmountInContract = stakingContract.getUserTotalStaked(user1);
        assertEq(stakedAmountInContract, STAKE_AMOUNT * 10);

    }

    function test_can_claim_rewards() external {
        vm.startPrank(user1);

        token.approve(address(stakingContract), STAKE_AMOUNT);
        stakingContract.deposit(STAKE_AMOUNT);

        uint256 userBalanceAfterStaking = token.balanceOf(user1);
        vm.warp(block.timestamp + TEN_DAYS_IN_SECOND);
        stakingContract.claimRewards();
        
        uint256 userBalanceAfterClaimingRewards = token.balanceOf(user1);

        vm.stopPrank();
        assert(userBalanceAfterClaimingRewards > userBalanceAfterStaking);

    }

    function test_can_claim_exact_rewards_correctly() external {
        vm.startPrank(user1);

        token.approve(address(stakingContract), STAKE_AMOUNT);
        uint256 time_now = 1747676389;
        vm.warp(time_now);
        stakingContract.deposit(STAKE_AMOUNT);
        console.log("Block.timestamp: ", block.timestamp);

        uint256 userBalanceAfterStaking = token.balanceOf(user1);
        vm.warp(time_now + TEN_DAYS_IN_SECOND);
        stakingContract.claimRewards();
        
        uint256 userBalanceAfterClaimingRewards = token.balanceOf(user1);
        uint256 expectedReward = 27397260273972602;
        vm.stopPrank();

        assert((userBalanceAfterClaimingRewards - userBalanceAfterStaking) == expectedReward);

    }

    function test_can_withdraw() external {
        vm.startPrank(user1);
        
        token.approve(address(stakingContract), STAKE_AMOUNT);
        
        stakingContract.deposit(STAKE_AMOUNT);
        
        vm.warp(TEN_DAYS_IN_SECOND);
        stakingContract.withdraw(STAKE_AMOUNT);

        uint256 userStakedBalanceAfterWithdraw = stakingContract.getUserTotalStaked(user1);

        vm.stopPrank();
        uint256 expected = 0;
        assert(userStakedBalanceAfterWithdraw == expected);

    }

    function test_can_withdraw_partially() external {
        vm.startPrank(user1);
        
        token.approve(address(stakingContract), STAKE_AMOUNT);
        
        stakingContract.deposit(STAKE_AMOUNT);

        vm.warp(TEN_DAYS_IN_SECOND);
        uint256 amountToWithdraw = STAKE_AMOUNT - 1e18;
        stakingContract.withdraw(amountToWithdraw);

        uint256 userStakedBalanceAfterWithdraw = stakingContract.getUserTotalStaked(user1);
        uint256 expected = 1e18;

        assert(userStakedBalanceAfterWithdraw == expected);

    }

    function test_can_withdraw_multiple_stakes() external {
        vm.startPrank(user1);
        
        token.approve(address(stakingContract), STAKE_AMOUNT * 20);
        
        stakingContract.deposit(STAKE_AMOUNT);
        stakingContract.deposit(STAKE_AMOUNT * 2);
        stakingContract.deposit(STAKE_AMOUNT * 3);
        
        vm.warp(TEN_DAYS_IN_SECOND);
        uint256 amountToWithdraw = STAKE_AMOUNT * 6;
        stakingContract.withdraw(amountToWithdraw);

        uint256 userStakedBalanceAfterWithdraw = stakingContract.getUserTotalStaked(user1);
        uint256 expected = 0;
        assert(userStakedBalanceAfterWithdraw == expected);

        // Testing partiall withdraw with multiple stakes
        stakingContract.deposit(STAKE_AMOUNT);
        stakingContract.deposit(STAKE_AMOUNT * 2);
        stakingContract.deposit(STAKE_AMOUNT * 2);

        vm.warp(TEN_DAYS_IN_SECOND * 2);
        amountToWithdraw = STAKE_AMOUNT * 3;
        stakingContract.withdraw(amountToWithdraw);

        expected = STAKE_AMOUNT * 2;
        userStakedBalanceAfterWithdraw = stakingContract.getUserTotalStaked(user1);
        assert(expected == userStakedBalanceAfterWithdraw);

    }
    
}