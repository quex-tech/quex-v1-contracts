// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {QuexDiamond} from "../../../../contracts/diamond/QuexDiamond.sol";
import {
    IConstantMaxResponseBlocksFacet,
    ConstantMaxResponseBlocksFacet
} from "../../../../contracts/facets/oracles/common/constant_max_response_blocks/ConstantMaxResponseBlocksFacet.sol";
import {IERC2535DiamondCutInternal} from "@solidstate/contracts/interfaces/IERC2535DiamondCutInternal.sol";
import {Test} from "forge-std/Test.sol";
import {QuexRoles} from "../../../../contracts/QuexRoles.sol";

contract ConstantMaxResponseBlocksFacetTest is Test {
    QuexDiamond internal diamond;
    IConstantMaxResponseBlocksFacet internal testObject;

    address private manager = vm.createWallet("manager").addr;

    function setUp() public virtual {
        diamond = new QuexDiamond();
        diamond.init(address(this));
        diamond.grantRole(QuexRoles.MANAGER, manager);

        ConstantMaxResponseBlocksFacet facet = new ConstantMaxResponseBlocksFacet();
        IERC2535DiamondCutInternal.FacetCut[] memory cuts = new IERC2535DiamondCutInternal.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](2);

        selectors[0] = ConstantMaxResponseBlocksFacet.getMaxResponseBlocks.selector;
        selectors[1] = ConstantMaxResponseBlocksFacet.setMaxResponseBlocks.selector;

        cuts[0] = IERC2535DiamondCutInternal.FacetCut({
            target: address(facet),
            action: IERC2535DiamondCutInternal.FacetCutAction.ADD,
            selectors: selectors
        });

        diamond.diamondCut(cuts, address(0), "");
        testObject = IConstantMaxResponseBlocksFacet(address(diamond));
    }

    function testFuzz_setMaxResponseBlocks_SetsBlocks(uint256 blocks) public {
        vm.prank(manager);
        testObject.setMaxResponseBlocks(blocks);

        vm.assertEq(blocks, testObject.getMaxResponseBlocks(0));
    }

    function test_setMaxResponseBlocks_RevertsIf_CallerIsNotManager() public {
        vm.expectRevert();
        testObject.setMaxResponseBlocks(100);
    }
}
