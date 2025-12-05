// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {YieldHarvesterStorage} from "./YieldHarvesterStorage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

error YieldHarvester_InvalidAmount();
error YieldHarvester_StrategyInactive();
error YieldHarvester_EmergencyStop();
error YieldHarvester_CooldownActive();
error YieldHarvester_InsufficientBalance();
error YieldHarvester_InvalidStrategy();
error YieldHarvester_Unauthorized();

abstract contract YieldHarvesterBase {
    using SafeERC20 for IERC20;

    function _validateDeposit(uint256 amount, uint256 strategyId) internal view {
        YieldHarvesterStorage.Layout storage l = YieldHarvesterStorage.layout();
        
        if (l.emergencyStop) revert YieldHarvester_EmergencyStop();
        if (amount == 0) revert YieldHarvester_InvalidAmount();
        if (amount < l.minDeposit && l.minDeposit > 0) revert YieldHarvester_InvalidAmount();
        if (amount > l.maxDeposit && l.maxDeposit > 0) revert YieldHarvester_InvalidAmount();
        
        YieldHarvesterStorage.Strategy storage strategy = l.strategies[strategyId];
        if (!strategy.active) revert YieldHarvester_StrategyInactive();
    }

    function _calculateYield(uint256 strategyId, address user) internal view returns (uint256) {
        YieldHarvesterStorage.Layout storage l = YieldHarvesterStorage.layout();
        YieldHarvesterStorage.Strategy storage strategy = l.strategies[strategyId];
        YieldHarvesterStorage.UserPosition storage position = l.userPositions[user];
        
        uint256 userDeposit = position.strategyDeposits[strategyId];
        if (userDeposit == 0) return 0;

        uint256 timeElapsed = block.timestamp - position.lastHarvestTime;
        if (timeElapsed == 0) return 0;

        // Simple Interest Calculation for Hackathon Demo: (Principal * Rate * Time) / (365 days * 10000)
        // APR is in basis points (e.g. 500 = 5%)
        uint256 yield = (userDeposit * strategy.apr * timeElapsed) / (365 days * 10000);
        
        return yield;
    }

    function _distributeFees(uint256 grossYield) internal returns (uint256 netYield, uint256 fee) {
        YieldHarvesterStorage.Layout storage l = YieldHarvesterStorage.layout();
        
        if (l.performanceFee > 0 && l.feeCollector != address(0)) {
            fee = (grossYield * l.performanceFee) / 10000;
            l.totalFeesCollected += fee;
            netYield = grossYield - fee;
        } else {
            fee = 0;
            netYield = grossYield;
        }
    }
}
