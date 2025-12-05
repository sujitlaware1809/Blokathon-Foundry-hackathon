// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseScript} from "script/Base.s.sol";
import {console} from "forge-std/console.sol";
import {IDiamondCut} from "src/facets/baseFacets/cut/IDiamondCut.sol";
import {YieldHarvesterFacet} from "src/facets/utilityFacets/YieldHarvester/YieldHarvesterFacet.sol";

contract DeployYieldHarvesterScript is BaseScript {
    address internal diamondAddress;

    function run() public broadcaster {
        setUp();
        
        // Try to get from env, else use default
        if (vm.envOr("DIAMOND_ADDRESS", address(0)) != address(0)) {
            diamondAddress = vm.envAddress("DIAMOND_ADDRESS");
        } else {
            diamondAddress = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9;
        }

        console.log("==============================================");
        console.log("Deploying YieldHarvester Facet...");
        console.log("==============================================");
        
        // Deploy Facet
        YieldHarvesterFacet facet = new YieldHarvesterFacet();
        console.log("YieldHarvesterFacet deployed to:", address(facet));

        // Prepare function selectors
        bytes4[] memory functionSelectors = new bytes4[](15);
        functionSelectors[0] = YieldHarvesterFacet.deposit.selector;
        functionSelectors[1] = YieldHarvesterFacet.withdraw.selector;
        functionSelectors[2] = YieldHarvesterFacet.harvest.selector;
        functionSelectors[3] = YieldHarvesterFacet.harvestAll.selector;
        functionSelectors[4] = YieldHarvesterFacet.addStrategy.selector;
        functionSelectors[5] = YieldHarvesterFacet.updateStrategyApr.selector;
        functionSelectors[6] = YieldHarvesterFacet.setEmergencyStop.selector;
        functionSelectors[7] = YieldHarvesterFacet.setFeeCollector.selector;
        functionSelectors[8] = YieldHarvesterFacet.setPerformanceFee.selector;
        functionSelectors[9] = YieldHarvesterFacet.getUserTvl.selector;
        functionSelectors[10] = YieldHarvesterFacet.getBestStrategyForAsset.selector;
        functionSelectors[11] = YieldHarvesterFacet.calculateApy.selector;
        functionSelectors[12] = YieldHarvesterFacet.getStrategy.selector;
        functionSelectors[13] = YieldHarvesterFacet.setAiAgent.selector;
        functionSelectors[14] = YieldHarvesterFacet.autoRebalance.selector;

        console.log("Adding 15 functions to Diamond...");

        // Create facet cut
        IDiamondCut.FacetCut[] memory facetCuts = new IDiamondCut.FacetCut[](1);
        facetCuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        // Execute diamond cut
        IDiamondCut(diamondAddress).diamondCut(facetCuts, address(0), "");

        console.log("==============================================");
        console.log("SUCCESS! YieldHarvester Facet added to Diamond!");
        console.log("==============================================");
    }
}
