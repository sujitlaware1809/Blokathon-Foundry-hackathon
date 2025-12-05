// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library YieldHarvesterStorage {
    bytes32 constant STORAGE_POSITION = keccak256("yield.harvester.storage");

    enum Protocol { AAVE, COMPOUND, YEARN, NONE }

    struct Strategy {
        address asset;
        Protocol protocol;
        uint256 apr;           // Annual Percentage Rate (basis points, e.g., 500 = 5%)
        uint256 totalDeposited;
        uint256 totalEarned;
        bool active;
    }

    struct UserPosition {
        uint256 totalDeposited;
        uint256 lastHarvestTime;
        uint256 pendingRewards;
        mapping(uint256 => uint256) strategyDeposits; // strategyId => amount
    }

    struct Layout {
        // Protocol Configurations
        mapping(Protocol => address) protocolAddresses;
        mapping(Protocol => address) rewardTokens;

        // Strategies Management
        uint256 nextStrategyId;
        mapping(uint256 => Strategy) strategies;
        mapping(address => uint256[]) assetStrategies; // asset => strategyIds

        // User Positions
        mapping(address => UserPosition) userPositions;

        // System Settings
        uint256 performanceFee; // basis points (100=1%)
        uint256 minDeposit;
        uint256 maxDeposit;
        uint256 harvestCooldown;
        address feeCollector;
        bool emergencyStop;

        // Statistics
        uint256 totalTvl;
        uint256 totalFeesCollected;
        uint256 totalHarvests;
        
        // AI Agent
        address aiAgent;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            l.slot := position
        }
    }
}
