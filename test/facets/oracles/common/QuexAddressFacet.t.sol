// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {QuexDiamond} from "../../../../contracts/diamond/QuexDiamond.sol";
import {IQuexAddressFacet, QuexAddressFacet} from "../../../../contracts/facets/oracles/common/quex_address/QuexAddressFacet.sol";
import {IERC2535DiamondCutInternal} from "@solidstate/contracts/interfaces/IERC2535DiamondCutInternal.sol";
import {Test} from "forge-std/Test.sol";
import {QuexRoles} from "../../../../contracts/QuexRoles.sol";

contract QuexAddressFacetTest is Test {
    QuexDiamond internal diamond;
    IQuexAddressFacet internal testObject;

    address private manager = vm.createWallet("manager").addr;

    function setUp() public virtual {
        diamond = new QuexDiamond();
        diamond.init(address(this));
        diamond.grantRole(QuexRoles.MANAGER, manager);

        QuexAddressFacet facet = new QuexAddressFacet();
        IERC2535DiamondCutInternal.FacetCut[] memory cuts = new IERC2535DiamondCutInternal.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](2);

        selectors[0] = QuexAddressFacet.setQuexAddress.selector;
        selectors[1] = QuexAddressFacet.getQuexAddress.selector;

        cuts[0] = IERC2535DiamondCutInternal.FacetCut({
            target: address(facet),
            action: IERC2535DiamondCutInternal.FacetCutAction.ADD,
            selectors: selectors
        });

        diamond.diamondCut(cuts, address(0), "");
        testObject = IQuexAddressFacet(address(diamond));
    }

    function testFuzz_setQuexAddress_SetsAddress(address quexAddress) public {
        vm.assume(quexAddress != address(0));
        vm.prank(manager);
        testObject.setQuexAddress(quexAddress);

        vm.assertEq(quexAddress, testObject.getQuexAddress());
    }

    function test_setQuexAddress_RevertsIf_CallerIsNotManager() public {
        vm.expectRevert();
        testObject.setQuexAddress(address(100));
    }

    function test_setQuexAddress_RevertsIf_AddressIsZero() public {
        vm.prank(manager);
        vm.expectRevert("Quex address cannot be 0");
        testObject.setQuexAddress(address(0));
    }
}
