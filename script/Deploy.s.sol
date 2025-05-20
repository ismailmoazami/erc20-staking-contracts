// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Script } from "forge-std/Script.sol";
import { ERC20Staking } from "src/ERC20Staking.sol";
import { ERC20Mock } from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract Deploy is Script {

    uint256 public constant INITIAL_BALANCE = 1000e18;

    function run() public {
        deploy();
    }

    function deploy() public returns(ERC20Staking){
        address token = getTokenAddress();

        vm.startBroadcast();
        ERC20Staking stakingContract = new ERC20Staking(token);

        vm.stopBroadcast();
        return stakingContract;
    }

    function getTokenAddress() internal returns(address){
        if(block.chainid == 31337) {
            ERC20Mock token = new ERC20Mock();
            token.mint(msg.sender, INITIAL_BALANCE);
            return address(token);
        }

        address tokenAddress = vm.envAddress("TOKEN_ADDRESS"); // Must be set for Sepolia or real network
        return tokenAddress;
    }
}