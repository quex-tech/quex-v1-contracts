// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {QuexDiamond} from "../../../../contracts/diamond/QuexDiamond.sol";
import {ITreasuryFacet, TreasuryFacet} from "../../../../contracts/facets/oracles/common/treasury/TreasuryFacet.sol";
import {IERC2535DiamondCutInternal} from "@solidstate/contracts/interfaces/IERC2535DiamondCutInternal.sol";
import {Test} from "forge-std/Test.sol";
import {QuexRoles} from "../../../../contracts/QuexRoles.sol";

contract TreasuryFacetTest is Test {
    QuexDiamond internal diamond;
    ITreasuryFacet internal testObject;

    address private manager = vm.createWallet("manager").addr;

    function setUp() public virtual {
        diamond = new QuexDiamond();
        diamond.init(address(this));
        diamond.grantRole(QuexRoles.MANAGER, manager);

        TreasuryFacet facet = new TreasuryFacet();
        IERC2535DiamondCutInternal.FacetCut[] memory cuts = new IERC2535DiamondCutInternal.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](2);

        selectors[0] = TreasuryFacet.getTreasury.selector;
        selectors[1] = TreasuryFacet.setTreasury.selector;

        cuts[0] = IERC2535DiamondCutInternal.FacetCut({
            target: address(facet),
            action: IERC2535DiamondCutInternal.FacetCutAction.ADD,
            selectors: selectors
        });

        diamond.diamondCut(cuts, address(0), "");
        testObject = ITreasuryFacet(address(diamond));
    }

    function testFuzz_setTreasury_SetsAddress(address treasuryAddress) public {
        vm.assume(treasuryAddress != address(0));
        vm.prank(manager);
        testObject.setTreasury(treasuryAddress);

        vm.assertEq(treasuryAddress, testObject.getTreasury());
    }

    function test_setTreasury_RevertsIf_CallerIsNotManager(address treasuryAddress) public {
        vm.expectRevert();
        testObject.setTreasury(treasuryAddress);
    }

    function test_setTreasury_RevertsIf_ZeroAddress() public {
        vm.prank(manager);
        vm.expectRevert("Treasury cannot be zero address");
        testObject.setTreasury(address(0));
    }
}
