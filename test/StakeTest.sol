// SPDX-License-Identifier: MIT 
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { Stake } from "src/Stake.sol";
import { ERC20Mock } from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract StakeTest is Test {
    
    Stake stake;
    ERC20Mock token;

    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    uint256 constant STAKE_AMOUNT = 10e18;
    uint256 constant TEN_DAYS_IN_SECOND = 10 days;

    function setUp() external {
        token = new ERC20Mock();
        stake = new Stake(address(token));

        // minting some tokens
        uint256 amount = 500e18; 
        token.mint(user1, amount);
        token.mint(user2, amount);
        // minting tokens for stake contract for rewards
        token.mint(address(stake), amount);
    }

    function test_stake() external {
        vm.startPrank(user1);
        
        token.approve(address(stake), STAKE_AMOUNT);
        stake.stake(STAKE_AMOUNT);

        vm.stopPrank();
        uint256 stakedAmountInContract = stake.userStake(user1);
        assertEq(stakedAmountInContract, STAKE_AMOUNT);
    }

    function test_can_stake_many_times() external {
        vm.startPrank(user1);
        token.approve(address(stake), STAKE_AMOUNT * 10);
        for(uint256 i = 0; i < 10; i++) {
            stake.stake(STAKE_AMOUNT);
        }

        vm.stopPrank();
        uint256 stakedAmountInContract = stake.userStake(user1);
        assertEq(stakedAmountInContract, STAKE_AMOUNT * 10);

    }

    function test_can_claim_rewards() external {
        vm.startPrank(user1);

        token.approve(address(stake), STAKE_AMOUNT);
        stake.stake(STAKE_AMOUNT);

        uint256 userBalanceAfterStaking = token.balanceOf(user1);
        vm.warp(block.timestamp + TEN_DAYS_IN_SECOND);
        stake.claimRewards();
        
        uint256 userBalanceAfterClaimingRewards = token.balanceOf(user1);

        vm.stopPrank();
        uint256 stakedAmountInContract = stake.userStake(user1);
        assert(userBalanceAfterClaimingRewards > userBalanceAfterStaking);

    }

    function test_can_claim_exact_rewards_correctly() external {
        vm.startPrank(user1);

        token.approve(address(stake), STAKE_AMOUNT);
        uint256 time_now = 1747676389;
        vm.warp(time_now);
        stake.stake(STAKE_AMOUNT);
        console.log("Block.timestamp: ", block.timestamp);

        uint256 userBalanceAfterStaking = token.balanceOf(user1);
        vm.warp(time_now + TEN_DAYS_IN_SECOND);
        stake.claimRewards();
        
        uint256 userBalanceAfterClaimingRewards = token.balanceOf(user1);
        uint256 expectedReward = 27397260273972602;
        vm.stopPrank();

        assert((userBalanceAfterClaimingRewards - userBalanceAfterStaking) == expectedReward);

    }

    function test_can_withdraw() external {
        vm.startPrank(user1);
        
        token.approve(address(stake), STAKE_AMOUNT);
        
        stake.stake(STAKE_AMOUNT);
        
        vm.warp(TEN_DAYS_IN_SECOND);
        stake.withdraw(STAKE_AMOUNT);

        uint256 userStakedBalanceAfterWithdraw = stake.userStake(user1);

        vm.stopPrank();
        uint256 expected = 0;
        assert(userStakedBalanceAfterWithdraw == expected);

    }

    function test_can_withdraw_partially() external {
        vm.startPrank(user1);
        
        token.approve(address(stake), STAKE_AMOUNT);
        
        stake.stake(STAKE_AMOUNT);

        vm.warp(TEN_DAYS_IN_SECOND);
        uint256 amountToWithdraw = STAKE_AMOUNT - 1e18;
        stake.withdraw(amountToWithdraw);

        uint256 userStakedBalanceAfterWithdraw = stake.userStake(user1);
        uint256 expected = 1e18;

        assert(userStakedBalanceAfterWithdraw == expected);

    }

    function test_can_withdraw_multiple_stakes() external {
        vm.startPrank(user1);
        
        token.approve(address(stake), STAKE_AMOUNT * 20);
        
        stake.stake(STAKE_AMOUNT);
        stake.stake(STAKE_AMOUNT * 2);
        stake.stake(STAKE_AMOUNT * 3);
        
        vm.warp(TEN_DAYS_IN_SECOND);
        uint256 amountToWithdraw = STAKE_AMOUNT * 6;
        stake.withdraw(amountToWithdraw);

        uint256 userStakedBalanceAfterWithdraw = stake.userStake(user1);
        uint256 expected = 0;
        assert(userStakedBalanceAfterWithdraw == expected);

        // Testing partiall withdraw with multiple stakes
        stake.stake(STAKE_AMOUNT);
        stake.stake(STAKE_AMOUNT * 2);
        stake.stake(STAKE_AMOUNT * 2);

        vm.warp(TEN_DAYS_IN_SECOND * 2);
        amountToWithdraw = STAKE_AMOUNT * 3;
        stake.withdraw(amountToWithdraw);

        expected = STAKE_AMOUNT * 2;
        userStakedBalanceAfterWithdraw = stake.userStake(user1);
        assert(expected == userStakedBalanceAfterWithdraw);

    }
    
}