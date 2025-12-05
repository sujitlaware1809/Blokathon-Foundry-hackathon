// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Facet} from "src/facets/Facet.sol";
import {YieldHarvesterBase, YieldHarvester_InvalidStrategy, YieldHarvester_InsufficientBalance, YieldHarvester_InvalidAmount} from "./YieldHarvesterBase.sol";
import {YieldHarvesterStorage} from "./YieldHarvesterStorage.sol";
import {IYieldHarvester} from "./IYieldHarvester.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract YieldHarvesterFacet is Facet, YieldHarvesterBase, IYieldHarvester {
    using SafeERC20 for IERC20;

    function deposit(address asset, uint256 amount, uint256 strategyId) external override nonReentrant {
        _validateDeposit(amount, strategyId);
        
        YieldHarvesterStorage.Layout storage l = YieldHarvesterStorage.layout();
        YieldHarvesterStorage.Strategy storage strategy = l.strategies[strategyId];
        
        if (strategy.asset != asset) revert YieldHarvester_InvalidStrategy();

        // Transfer tokens from user
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

        // Update State
        YieldHarvesterStorage.UserPosition storage position = l.userPositions[msg.sender];
        
        // Harvest pending yield before updating position if not first deposit
        if (position.strategyDeposits[strategyId] > 0) {
            _harvest(msg.sender, strategyId);
        } else {
            position.lastHarvestTime = block.timestamp;
        }

        position.strategyDeposits[strategyId] += amount;
        position.totalDeposited += amount;
        
        strategy.totalDeposited += amount;
        l.totalTvl += amount;

        emit Deposit(msg.sender, asset, amount, strategyId);
    }

    function withdraw(uint256 amount, uint256 strategyId) external override nonReentrant {
        YieldHarvesterStorage.Layout storage l = YieldHarvesterStorage.layout();
        YieldHarvesterStorage.UserPosition storage position = l.userPositions[msg.sender];
        YieldHarvesterStorage.Strategy storage strategy = l.strategies[strategyId];

        if (position.strategyDeposits[strategyId] < amount) revert YieldHarvester_InsufficientBalance();

        // Harvest first
        _harvest(msg.sender, strategyId);

        // Update State
        position.strategyDeposits[strategyId] -= amount;
        position.totalDeposited -= amount;
        strategy.totalDeposited -= amount;
        l.totalTvl -= amount;

        // Transfer tokens back
        IERC20(strategy.asset).safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, strategy.asset, amount, strategyId);
    }

    function harvest(uint256 strategyId) external override nonReentrant {
        _harvest(msg.sender, strategyId);
    }

    function harvestAll() external override nonReentrant {
        YieldHarvesterStorage.Layout storage l = YieldHarvesterStorage.layout();
        // Iterate through all strategies (simplified for hackathon, in prod use enumerable set of user strategies)
        // For this demo, we'll just check the first 10 strategies
        for (uint256 i = 0; i < l.nextStrategyId && i < 10; i++) {
            if (l.userPositions[msg.sender].strategyDeposits[i] > 0) {
                _harvest(msg.sender, i);
            }
        }
    }

    function _harvest(address user, uint256 strategyId) internal {
        YieldHarvesterStorage.Layout storage l = YieldHarvesterStorage.layout();
        YieldHarvesterStorage.UserPosition storage position = l.userPositions[user];
        
        uint256 grossYield = _calculateYield(strategyId, user);
        if (grossYield == 0) return;

        (uint256 netYield, uint256 fee) = _distributeFees(grossYield);

        // Mint/Transfer rewards (Simulated by transferring from contract balance or minting)
        // For hackathon demo, we assume the contract has some "Reward" tokens or we just compound the base asset
        // Here we simulate auto-compounding by adding to the deposit
        
        // In a real scenario, we would swap reward tokens for the asset token here.
        // We will simulate that the yield is "realized" and added to the position.
        // NOTE: This assumes the contract has extra funds to pay out yield, or yield comes from external protocol.
        // For the demo, we will just track it as "earned" but not physically transfer unless we have a mint function.
        // To make it realistic for tests, we'll assume the contract is funded with rewards.
        
        position.strategyDeposits[strategyId] += netYield;
        position.totalDeposited += netYield;
        position.lastHarvestTime = block.timestamp;
        
        YieldHarvesterStorage.Strategy storage strategy = l.strategies[strategyId];
        strategy.totalEarned += netYield;
        strategy.totalDeposited += netYield;
        
        l.totalHarvests++;
        
        // Transfer fee if applicable
        if (fee > 0 && l.feeCollector != address(0)) {
             // Assuming fee is taken from the asset itself
             // In a real integration, we'd pull from the external protocol
        }

        emit Harvest(user, strategyId, netYield, fee);
    }

    // AI Agent Functions
    function setAiAgent(address _agent) external override onlyDiamondOwner {
        YieldHarvesterStorage.layout().aiAgent = _agent;
    }

    modifier onlyAiAgent() {
        _onlyAiAgent();
        _;
    }

    function _onlyAiAgent() internal view {
        if (msg.sender != YieldHarvesterStorage.layout().aiAgent) revert("Not AI Agent");
    }

    function autoRebalance(address user, address asset) external override onlyAiAgent nonReentrant {
        YieldHarvesterStorage.Layout storage l = YieldHarvesterStorage.layout();
        uint256 bestStrategyId = this.getBestStrategyForAsset(asset);
        
        uint256[] memory strategyIds = l.assetStrategies[asset];
        
        for (uint256 i = 0; i < strategyIds.length; i++) {
            uint256 currentId = strategyIds[i];
            if (currentId == bestStrategyId) continue;
            
            uint256 balance = l.userPositions[user].strategyDeposits[currentId];
            if (balance > 0) {
                _harvest(user, currentId);
                
                // Re-read balance after harvest
                balance = l.userPositions[user].strategyDeposits[currentId];
                
                // Move
                l.userPositions[user].strategyDeposits[currentId] = 0;
                l.strategies[currentId].totalDeposited -= balance;
                
                l.userPositions[user].strategyDeposits[bestStrategyId] += balance;
                l.strategies[bestStrategyId].totalDeposited += balance;
                
                emit Deposit(user, asset, balance, bestStrategyId);
            }
        }
    }

    // Management Functions
    function addStrategy(address asset, YieldHarvesterStorage.Protocol protocol, uint256 apr) external override onlyDiamondOwner {
        YieldHarvesterStorage.Layout storage l = YieldHarvesterStorage.layout();
        uint256 id = l.nextStrategyId++;
        
        l.strategies[id] = YieldHarvesterStorage.Strategy({
            asset: asset,
            protocol: protocol,
            apr: apr,
            totalDeposited: 0,
            totalEarned: 0,
            active: true
        });
        
        l.assetStrategies[asset].push(id);
        
        emit StrategyAdded(id, asset, protocol, apr);
    }

    function updateStrategyApr(uint256 strategyId, uint256 newApr) external override onlyDiamondOwner {
        YieldHarvesterStorage.Layout storage l = YieldHarvesterStorage.layout();
        l.strategies[strategyId].apr = newApr;
        emit StrategyUpdated(strategyId, newApr, l.strategies[strategyId].active);
    }

    function setEmergencyStop(bool stop) external override onlyDiamondOwner {
        YieldHarvesterStorage.Layout storage l = YieldHarvesterStorage.layout();
        l.emergencyStop = stop;
        emit EmergencyStop(stop);
    }

    function setFeeCollector(address collector) external override onlyDiamondOwner {
        YieldHarvesterStorage.Layout storage l = YieldHarvesterStorage.layout();
        l.feeCollector = collector;
    }

    function setPerformanceFee(uint256 feeBps) external override onlyDiamondOwner {
        YieldHarvesterStorage.Layout storage l = YieldHarvesterStorage.layout();
        if (feeBps > 1000) revert YieldHarvester_InvalidAmount(); // Max 10%
        l.performanceFee = feeBps;
    }

    // View Functions
    function getUserTvl(address user) external view override returns (uint256) {
        return YieldHarvesterStorage.layout().userPositions[user].totalDeposited;
    }

    function getBestStrategyForAsset(address asset) external view override returns (uint256) {
        YieldHarvesterStorage.Layout storage l = YieldHarvesterStorage.layout();
        uint256[] memory ids = l.assetStrategies[asset];
        
        uint256 bestId;
        uint256 bestApr = 0;
        
        for(uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            if (l.strategies[id].active && l.strategies[id].apr > bestApr) {
                bestApr = l.strategies[id].apr;
                bestId = id;
            }
        }
        return bestId;
    }

    function calculateApy(uint256 strategyId) external view override returns (uint256) {
        return YieldHarvesterStorage.layout().strategies[strategyId].apr;
    }

    function getStrategy(uint256 strategyId) external view override returns (YieldHarvesterStorage.Strategy memory) {
        return YieldHarvesterStorage.layout().strategies[strategyId];
    }
}
