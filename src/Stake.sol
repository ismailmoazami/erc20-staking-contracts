// SPDX-License-Identifier: MIT 
pragma solidity 0.8.20;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";

// Errors
error TransferFailed();
error NotEnoughValue();

contract Stake is Ownable {

    // Events
    event Staked(address sender, uint256 amount, uint256 id);
    event RewardsClaimed(address sender, uint256 amount);

    // Structs
    struct StakeInfo {
        uint256 amount;
        uint256 startedTime;
        uint256 id;
    }

    // State variables
    IERC20 public immutable TOKEN; 
    uint256 public BASE_REWARD_RATE = 10e17; // 10%
    uint256 public currentId; 
    uint256 public constant SECONDS_IN_YEAR = 365 days;
    uint256 public constant SCALING_FACTOR  = 1e18; 

    mapping(address => StakeInfo[]) public stakes;
     
    constructor(address _tokenAddress) Ownable(msg.sender) {
        TOKEN = IERC20(_tokenAddress);
        currentId = 1;
    }

    // Public and External functions
    function stake(uint256 _amount) public {
        bool success = TOKEN.transferFrom(msg.sender, address(this), _amount);
        
        if(!success) {
            revert TransferFailed();
        }

        StakeInfo memory user_stake = StakeInfo(_amount, block.timestamp, currentId);
        stakes[msg.sender].push(user_stake);
        currentId++;
        emit Staked(msg.sender, _amount, currentId);
    }

    function claimRewards() public {
        StakeInfo[] memory user_stakes = stakes[msg.sender];
        uint256 totalRewardsForUser = 0;
        for(uint i = 0; i < user_stakes.length; i++){
            StakeInfo memory info = user_stakes[i];
            if(info.amount == 0) continue;
            
            uint256 timeElpased = block.timestamp - info.startedTime;
            uint256 reward = calculateRewards(info.amount, timeElpased);

            stakes[msg.sender][i].startedTime = block.timestamp;
            totalRewardsForUser += reward;
        }

        if(totalRewardsForUser == 0) {
            revert NotEnoughValue();
        }
        
        bool success = TOKEN.transfer(msg.sender, totalRewardsForUser);
        if(!success) {
            revert TransferFailed();
        }

        emit RewardsClaimed(msg.sender, totalRewardsForUser);
    }

    function setBaseRewardRate(uint256 _newRate) public onlyOwner {
        BASE_REWARD_RATE = _newRate;
    }

    function rewardPool() public view returns(uint256) {
        return TOKEN.balanceOf(address(this));
    }

    function userStake(address _user) public view returns(uint256 totalRewardsForUser) {
        for(uint i = 0; i < stakes[_user].length; i++){
            totalRewardsForUser += stakes[_user][i].amount; 
        }
    }

    // Internal and Private functions
    function calculateRewards(uint256 _amount, uint256 timeElapsed) public view returns (uint256) {
        // (_amount * 0.10 * timeElapsed) / (1 year)
        return (_amount * BASE_REWARD_RATE * timeElapsed) / (SECONDS_IN_YEAR * SCALING_FACTOR);
    } 

}