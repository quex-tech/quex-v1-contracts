// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../../../contracts/diamond/QuexDiamond.sol";
import "../../../../contracts/facets/oracles/common/td_policy_facet/TrustDomainPolicyFacet.sol";
import "@solidstate/contracts/interfaces/IERC2535DiamondCutInternal.sol";
import "forge-std/Script.sol";
import "forge-std/Test.sol";

contract TrustDomainPolicyFacetTest is Test {
    QuexDiamond internal diamond;
    ITrustDomainPolicyFacet internal testObject;

    address private manager = vm.createWallet("manager").addr;

    function setUp() public virtual {
        diamond = new QuexDiamond();
        diamond.init();
        diamond.grantRole(QuexRoles.Manager, manager);

        TrustDomainPolicyFacet facet = new TrustDomainPolicyFacet();
        IERC2535DiamondCutInternal.FacetCut[] memory cuts = new IERC2535DiamondCutInternal.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](3);

        selectors[0] = TrustDomainPolicyFacet.isInPool.selector;
        selectors[1] = TrustDomainPolicyFacet.addToPool.selector;
        selectors[2] = TrustDomainPolicyFacet.removeFromPool.selector;

        cuts[0] = IERC2535DiamondCutInternal.FacetCut({
            target: address(facet),
            action: IERC2535DiamondCutInternal.FacetCutAction.ADD,
            selectors: selectors
        });

        diamond.diamondCut(cuts, address(0), "");
        testObject = ITrustDomainPolicyFacet(address(diamond));
    }

    function testFuzz_addToPool_AddsTDToPool(uint256 tdId) public {
        vm.prank(manager);
        testObject.addToPool(tdId);

        vm.assertTrue(testObject.isInPool(tdId));
    }

    function testFuzz_removeFromPool_RemovesTDFromPool(uint256 tdId) public {
        vm.prank(manager);
        testObject.addToPool(tdId);

        vm.prank(manager);
        testObject.removeFromPool(tdId);

        vm.assertFalse(testObject.isInPool(tdId));
    }

    function testFuzz_removeFromPool_DoesNotRevertIf_TDIsNotInPool(uint256 tdId) public {
        vm.prank(manager);
        testObject.removeFromPool(tdId);

        vm.assertFalse(testObject.isInPool(tdId));
    }

    function test_addToPool_RevertsIf_CallerIsNotManager(uint256 tdId) public {
        vm.expectRevert();
        testObject.addToPool(tdId);
    }

    function test_removeFromPool_RevertsIf_CallerIsNotManager(uint256 tdId) public {
        vm.expectRevert();
        testObject.removeFromPool(tdId);
    }
}
