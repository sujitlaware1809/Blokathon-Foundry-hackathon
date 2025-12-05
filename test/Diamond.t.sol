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

contract DiamondTest is Test {
    Diamond public diamond;
    DiamondCutFacet public diamondCutFacet;
    DiamondLoupeFacet public diamondLoupeFacet;
    OwnershipFacet public ownershipFacet;

    address public owner;
    address public user1;
    address public user2;

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Deploy facets
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();

        // Build facet cuts
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
    }

    function test_DiamondDeployment() public view {
        assertEq(IERC173(address(diamond)).owner(), owner);
    }

    function test_SupportsInterface() public view {
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IERC165).interfaceId));
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IDiamondCut).interfaceId));
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IDiamondLoupe).interfaceId));
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IERC173).interfaceId));
    }

    function test_FacetAddresses() public view {
        address[] memory facetAddresses = IDiamondLoupe(address(diamond)).facetAddresses();
        assertEq(facetAddresses.length, 3);
        assertEq(facetAddresses[0], address(diamondCutFacet));
        assertEq(facetAddresses[1], address(diamondLoupeFacet));
        assertEq(facetAddresses[2], address(ownershipFacet));
    }

    function test_FacetFunctionSelectors() public view {
        bytes4[] memory selectors = IDiamondLoupe(address(diamond)).facetFunctionSelectors(address(diamondCutFacet));
        assertEq(selectors.length, 1);
        assertEq(selectors[0], IDiamondCut.diamondCut.selector);
    }

    function test_FacetAddress() public view {
        address facetAddr = IDiamondLoupe(address(diamond)).facetAddress(IDiamondCut.diamondCut.selector);
        assertEq(facetAddr, address(diamondCutFacet));
    }

    function test_Facets() public view {
        IDiamondLoupe.Facet[] memory facets = IDiamondLoupe(address(diamond)).facets();
        assertEq(facets.length, 3);
        assertEq(facets[0].facetAddress, address(diamondCutFacet));
        assertEq(facets[1].facetAddress, address(diamondLoupeFacet));
        assertEq(facets[2].facetAddress, address(ownershipFacet));
    }

    function test_OwnershipTransfer() public {
        assertEq(IERC173(address(diamond)).owner(), owner);

        vm.expectEmit(true, true, false, true);
        emit OwnershipTransferred(owner, user1);
        IERC173(address(diamond)).transferOwnership(user1);

        assertEq(IERC173(address(diamond)).owner(), user1);
    }

    function test_RevertWhen_OwnershipTransferUnauthorized() public {
        vm.expectRevert();
        vm.prank(user1);
        IERC173(address(diamond)).transferOwnership(user2);
    }

    function test_OwnerIsCorrect() public view {
        assertEq(IERC173(address(diamond)).owner(), owner);
    }

    function test_RevertWhen_DiamondCutUnauthorized() public {
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](0);
        
        vm.expectRevert();
        vm.prank(user1);
        IDiamondCut(address(diamond)).diamondCut(cuts, address(0), "");
    }

    function test_DiamondCutAddFacet() public {
        // Deploy a new test facet
        OwnershipFacet newFacet = new OwnershipFacet();
        
        // Create a new function selector for testing
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = bytes4(keccak256("testFunction()"));
        
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(newFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        vm.expectEmit(false, false, false, false);
        emit DiamondCut(cuts, address(0), "");
        IDiamondCut(address(diamond)).diamondCut(cuts, address(0), "");

        // Verify the facet was added
        address facetAddr = IDiamondLoupe(address(diamond)).facetAddress(selectors[0]);
        assertEq(facetAddr, address(newFacet));
    }

    function test_DiamondReceivesEther() public {
        uint256 amount = 1 ether;
        vm.deal(user1, amount);
        
        vm.prank(user1);
        (bool success,) = address(diamond).call{value: amount}("");
        
        assertTrue(success);
        assertEq(address(diamond).balance, amount);
    }
}
