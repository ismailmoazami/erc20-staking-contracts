// SPDX-License-Identifier: MIT 
pragma solidity 0.8.20;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

// Errors
error TransferFailed();
error NotEnoughValue();

contract ERC20Staking is Ownable, ReentrancyGuard{

    // Events
    event Staked(address sender, uint256 amount, uint256 id);
    event RewardsClaimed(address sender, uint256 amount);
    event TokensWithdrawn(address sender, uint256 amount);

    // Structs
    struct StakeInfo {
        uint256 amount;
        uint256 startedTime;
        uint256 id;
    }

    // State variables
    IERC20 public immutable TOKEN; 
    uint256 public REWARD_RATE_PER_YEAR = 10e16; // 10%
    uint256 public currentId; 
    uint256 public constant SECONDS_IN_YEAR = 365 days;
    uint256 public constant SCALING_FACTOR  = 1e18; 

    mapping(address => StakeInfo[]) public stakes;
     
    constructor(address _tokenAddress) Ownable(msg.sender) {
        TOKEN = IERC20(_tokenAddress);
        currentId = 1;
    }

    // Public and External functions
    function deposit(uint256 _amount) public {
        bool success = TOKEN.transferFrom(msg.sender, address(this), _amount);
        
        if(!success) {
            revert TransferFailed();
        }

        StakeInfo memory user_stake = StakeInfo(_amount, block.timestamp, currentId);
        stakes[msg.sender].push(user_stake);
        
        emit Staked(msg.sender, _amount, currentId);
        currentId++;
    }

    function claimRewards() public nonReentrant {
        StakeInfo[] storage user_stakes = stakes[msg.sender];
        uint256 totalRewardsForUser = 0;
        uint256 user_stakes_length = user_stakes.length;
        for(uint i = 0; i < user_stakes_length; i++){
            StakeInfo memory info = user_stakes[i];
            if(info.amount == 0) continue;
            
            uint256 timeElpased = block.timestamp - info.startedTime;
            uint256 reward = calculateRewards(info.amount, timeElpased);

            user_stakes[i].startedTime = block.timestamp;
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

    function withdraw(uint256 _amountToWithdraw) public nonReentrant {
        if(getUserTotalStaked(msg.sender) < _amountToWithdraw) {
            revert NotEnoughValue();
        }

        uint256 total = 0;
        StakeInfo[] storage user_stakes = stakes[msg.sender];
        uint i = 0;
        while(total < _amountToWithdraw) {
            StakeInfo memory info = user_stakes[i];
            if(info.amount == 0) {
                i++;
                continue;
            }
            if((total + info.amount) > _amountToWithdraw) {
                uint256 difference = _amountToWithdraw - total;
                user_stakes[i].amount -= difference;
                total += difference;
            } else {
                total += info.amount;
                user_stakes[i].amount = 0;
            }
            i++;
            
        }

        bool success = TOKEN.transfer(msg.sender, total);
        if(!success) {
            revert TransferFailed();
        }

        emit TokensWithdrawn(msg.sender, total);

    }

    function setRewardRatePerYear(uint256 _newRate) public onlyOwner {
        REWARD_RATE_PER_YEAR = _newRate;
    }

    function rewardPool() public view returns(uint256) {
        return TOKEN.balanceOf(address(this));
    }

    function getUserTotalStaked(address _user) public view returns(uint256 totalStaked) {
        for(uint i = 0; i < stakes[_user].length; i++){
            totalStaked += stakes[_user][i].amount; 
        }
    }

    // Internal and Private functions
    function calculateRewards(uint256 _amount, uint256 timeElapsed) internal view returns (uint256) {
        // (_amount * 0.10 * timeElapsed) / (1 year)
        return (_amount * REWARD_RATE_PER_YEAR * timeElapsed) / (SECONDS_IN_YEAR * SCALING_FACTOR);
    } 

}