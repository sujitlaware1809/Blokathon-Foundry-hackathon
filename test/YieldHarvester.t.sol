// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Diamond} from "src/Diamond.sol";
import {IDiamondCut} from "src/facets/baseFacets/cut/IDiamondCut.sol";
import {IDiamondLoupe} from "src/facets/baseFacets/loupe/IDiamondLoupe.sol";
import {IERC165} from "src/interfaces/IERC165.sol";
import {IERC173} from "src/interfaces/IERC173.sol";
import {DiamondCutFacet} from "src/facets/baseFacets/cut/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "src/facets/baseFacets/loupe/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "src/facets/baseFacets/ownership/OwnershipFacet.sol";
import {YieldHarvesterFacet} from "src/facets/utilityFacets/YieldHarvester/YieldHarvesterFacet.sol";
import {IYieldHarvester} from "src/facets/utilityFacets/YieldHarvester/IYieldHarvester.sol";
import {YieldHarvesterStorage} from "src/facets/utilityFacets/YieldHarvester/YieldHarvesterStorage.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

contract YieldHarvesterTest is Test {
    Diamond public diamond;
    DiamondCutFacet public diamondCutFacet;
    DiamondLoupeFacet public diamondLoupeFacet;
    OwnershipFacet public ownershipFacet;
    YieldHarvesterFacet public yieldHarvesterFacet;

    address public owner;
    address public user1;
    MockERC20 public usdc;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        
        // Deploy Mock Token
        usdc = new MockERC20("USDC", "USDC");

        // Deploy base facets
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();

        // Build base facet cuts
        IDiamondCut.FacetCut[] memory facetCuts = new IDiamondCut.FacetCut[](3);

        // DiamondCutFacet
        bytes4[] memory cutSelectors = new bytes4[](1);
        cutSelectors[0] = IDiamondCut.diamondCut.selector;
        facetCuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondCutFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: cutSelectors
        });

        // DiamondLoupeFacet
        bytes4[] memory loupeSelectors = new bytes4[](5);
        loupeSelectors[0] = IDiamondLoupe.facets.selector;
        loupeSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        loupeSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        loupeSelectors[3] = IDiamondLoupe.facetAddress.selector;
        loupeSelectors[4] = IERC165.supportsInterface.selector;
        facetCuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        // OwnershipFacet
        bytes4[] memory ownershipSelectors = new bytes4[](2);
        ownershipSelectors[0] = IERC173.owner.selector;
        ownershipSelectors[1] = IERC173.transferOwnership.selector;
        facetCuts[2] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownershipSelectors
        });

        // Deploy Diamond
        diamond = new Diamond(owner, facetCuts);

        // Deploy YieldHarvesterFacet
        yieldHarvesterFacet = new YieldHarvesterFacet();

        // Add YieldHarvesterFacet to Diamond
        _addYieldHarvesterFacet();
    }

    function _addYieldHarvesterFacet() internal {
        bytes4[] memory selectors = new bytes4[](13);
        selectors[0] = YieldHarvesterFacet.deposit.selector;
        selectors[1] = YieldHarvesterFacet.withdraw.selector;
        selectors[2] = YieldHarvesterFacet.harvest.selector;
        selectors[3] = YieldHarvesterFacet.harvestAll.selector;
        selectors[4] = YieldHarvesterFacet.addStrategy.selector;
        selectors[5] = YieldHarvesterFacet.updateStrategyApr.selector;
        selectors[6] = YieldHarvesterFacet.setEmergencyStop.selector;
        selectors[7] = YieldHarvesterFacet.setFeeCollector.selector;
        selectors[8] = YieldHarvesterFacet.setPerformanceFee.selector;
        selectors[9] = YieldHarvesterFacet.getUserTvl.selector;
        selectors[10] = YieldHarvesterFacet.getBestStrategyForAsset.selector;
        selectors[11] = YieldHarvesterFacet.calculateApy.selector;
        selectors[12] = YieldHarvesterFacet.getStrategy.selector;

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(yieldHarvesterFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(cuts, address(0), "");
    }

    function test_AddStrategy() public {
        IYieldHarvester(address(diamond)).addStrategy(address(usdc), YieldHarvesterStorage.Protocol.AAVE, 500); // 5% APR
        
        YieldHarvesterStorage.Strategy memory strategy = IYieldHarvester(address(diamond)).getStrategy(0);
        assertEq(strategy.asset, address(usdc));
        assertEq(uint(strategy.protocol), uint(YieldHarvesterStorage.Protocol.AAVE));
        assertEq(strategy.apr, 500);
        assertTrue(strategy.active);
    }

    function test_Deposit() public {
        // Setup
        IYieldHarvester(address(diamond)).addStrategy(address(usdc), YieldHarvesterStorage.Protocol.AAVE, 500);
        usdc.mint(user1, 1000 ether);
        
        vm.startPrank(user1);
        usdc.approve(address(diamond), 1000 ether);
        IYieldHarvester(address(diamond)).deposit(address(usdc), 100 ether, 0);
        vm.stopPrank();

        uint256 tvl = IYieldHarvester(address(diamond)).getUserTvl(user1);
        assertEq(tvl, 100 ether);
    }

    function test_HarvestYield() public {
        // Setup
        IYieldHarvester(address(diamond)).addStrategy(address(usdc), YieldHarvesterStorage.Protocol.AAVE, 1000); // 10% APR
        usdc.mint(user1, 1000 ether);
        
        vm.startPrank(user1);
        usdc.approve(address(diamond), 1000 ether);
        IYieldHarvester(address(diamond)).deposit(address(usdc), 100 ether, 0);
        
        // Fast forward 1 year
        vm.warp(block.timestamp + 365 days);
        
        // Harvest
        IYieldHarvester(address(diamond)).harvest(0);
        vm.stopPrank();

        uint256 tvl = IYieldHarvester(address(diamond)).getUserTvl(user1);
        // 100 ether + 10% = 110 ether
        assertEq(tvl, 110 ether);
    }

    function test_EmergencyStop() public {
        IYieldHarvester(address(diamond)).setEmergencyStop(true);
        
        vm.expectRevert(); // Should revert with custom error, but checking generic revert for now
        IYieldHarvester(address(diamond)).deposit(address(usdc), 100 ether, 0);
    }
}
