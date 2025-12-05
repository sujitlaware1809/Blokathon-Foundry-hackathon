// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {YieldHarvesterStorage} from "./YieldHarvesterStorage.sol";

interface IYieldHarvester {
    // Events
    event Deposit(address indexed user, address indexed asset, uint256 amount, uint256 strategyId);
    event Withdraw(address indexed user, address indexed asset, uint256 amount, uint256 strategyId);
    event Harvest(address indexed user, uint256 strategyId, uint256 yield, uint256 fee);
    event StrategyAdded(uint256 indexed strategyId, address indexed asset, YieldHarvesterStorage.Protocol protocol, uint256 apr);
    event StrategyUpdated(uint256 indexed strategyId, uint256 newApr, bool active);
    event EmergencyStop(bool stopped);

    // User Functions
    function deposit(address asset, uint256 amount, uint256 strategyId) external;
    function withdraw(uint256 amount, uint256 strategyId) external;
    function harvest(uint256 strategyId) external;
    function harvestAll() external;
    
    // AI Agent Functions
    function setAiAgent(address _agent) external;
    function autoRebalance(address user, address asset) external;

    // Management Functions (Owner Only)
    function addStrategy(address asset, YieldHarvesterStorage.Protocol protocol, uint256 apr) external;
    function updateStrategyApr(uint256 strategyId, uint256 newApr) external;
    function setEmergencyStop(bool stop) external;
    function setFeeCollector(address collector) external;
    function setPerformanceFee(uint256 feeBps) external;

    // View Functions
    function getUserTvl(address user) external view returns (uint256);
    function getBestStrategyForAsset(address asset) external view returns (uint256);
    function calculateApy(uint256 strategyId) external view returns (uint256);
    function getStrategy(uint256 strategyId) external view returns (YieldHarvesterStorage.Strategy memory);
}
