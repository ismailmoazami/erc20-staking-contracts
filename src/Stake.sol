// SPDX-License-Identifier: MIT 
pragma solidity 0.8.20;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// Errors
error TransferFailed();

contract Stake{

    // Events
    event Staked(address sender, uint256 amount);

    IERC20 public immutable TOKEN; 
    mapping(address => uint256) public stakes;

    constructor(address _tokenAddress) {
        TOKEN = IERC20(_tokenAddress);
    }

    function stake(uint256 _amount) public {
        bool success = TOKEN.transferFrom(msg.sender, address(this), _amount);
        
        if(!success) {
            revert TransferFailed();
        }

        stakes[msg.sender] += _amount;
        emit Staked(msg.sender, _amount);
    }

}