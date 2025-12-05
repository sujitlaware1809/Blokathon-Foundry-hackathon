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
import {AaveV3Facet} from "src/facets/utilityFacets/aaveV3/AaveV3Facet.sol";

/// @notice Basic test for AaveV3Facet integration with Diamond
/// @dev This test verifies that the AaveV3Facet can be added to the Diamond
contract AaveV3FacetTest is Test {
    Diamond public diamond;
    DiamondCutFacet public diamondCutFacet;
    DiamondLoupeFacet public diamondLoupeFacet;
    OwnershipFacet public ownershipFacet;
    AaveV3Facet public aaveV3Facet;

    address public owner;
    address public user1;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");

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

        // Deploy AaveV3Facet
        aaveV3Facet = new AaveV3Facet();
    }

    function test_AddAaveV3Facet() public {
        // Add AaveV3Facet selectors
        bytes4[] memory aaveSelectors = new bytes4[](3);
        aaveSelectors[0] = AaveV3Facet.getReserveData.selector;
        aaveSelectors[1] = AaveV3Facet.lend.selector;
        aaveSelectors[2] = AaveV3Facet.withdraw.selector;

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(aaveV3Facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: aaveSelectors
        });

        // Add the facet
        IDiamondCut(address(diamond)).diamondCut(cuts, address(0), "");

        // Verify the facet was added
        address facetAddr = IDiamondLoupe(address(diamond)).facetAddress(AaveV3Facet.lend.selector);
        assertEq(facetAddr, address(aaveV3Facet));

        // Verify all selectors are mapped correctly
        bytes4[] memory facetSelectors = IDiamondLoupe(address(diamond)).facetFunctionSelectors(address(aaveV3Facet));
        assertEq(facetSelectors.length, 3);
    }

    function test_AaveV3FacetIsInFacetList() public {
        // Add AaveV3Facet
        bytes4[] memory aaveSelectors = new bytes4[](3);
        aaveSelectors[0] = AaveV3Facet.getReserveData.selector;
        aaveSelectors[1] = AaveV3Facet.lend.selector;
        aaveSelectors[2] = AaveV3Facet.withdraw.selector;

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(aaveV3Facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: aaveSelectors
        });

        IDiamondCut(address(diamond)).diamondCut(cuts, address(0), "");

        // Verify facet count
        address[] memory facetAddresses = IDiamondLoupe(address(diamond)).facetAddresses();
        assertEq(facetAddresses.length, 4); // 3 base facets + 1 AaveV3Facet

        // Verify AaveV3Facet is in the list
        bool found = false;
        for (uint256 i = 0; i < facetAddresses.length; i++) {
            if (facetAddresses[i] == address(aaveV3Facet)) {
                found = true;
                break;
            }
        }
        assertTrue(found);
    }

    function test_RevertWhen_UnauthorizedLend() public {
        // Add AaveV3Facet
        bytes4[] memory aaveSelectors = new bytes4[](3);
        aaveSelectors[0] = AaveV3Facet.getReserveData.selector;
        aaveSelectors[1] = AaveV3Facet.lend.selector;
        aaveSelectors[2] = AaveV3Facet.withdraw.selector;

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(aaveV3Facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: aaveSelectors
        });

        IDiamondCut(address(diamond)).diamondCut(cuts, address(0), "");

        // Try to call lend from non-owner (should fail)
        vm.expectRevert();
        vm.prank(user1);
        AaveV3Facet(address(diamond)).lend(address(0), 100);
    }

    function test_RevertWhen_UnauthorizedWithdraw() public {
        // Add AaveV3Facet
        bytes4[] memory aaveSelectors = new bytes4[](3);
        aaveSelectors[0] = AaveV3Facet.getReserveData.selector;
        aaveSelectors[1] = AaveV3Facet.lend.selector;
        aaveSelectors[2] = AaveV3Facet.withdraw.selector;

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(aaveV3Facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: aaveSelectors
        });

        IDiamondCut(address(diamond)).diamondCut(cuts, address(0), "");

        // Try to call withdraw from non-owner (should fail)
        vm.expectRevert();
        vm.prank(user1);
        AaveV3Facet(address(diamond)).withdraw(address(0), 100);
    }
}
