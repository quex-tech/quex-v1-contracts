// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../../../contracts/diamond/QuexDiamond.sol";
import "../../../../contracts/facets/oracles/common/monetary_constant_price/ConstantPriceMonetaryFacet.sol";
import "@solidstate/contracts/interfaces/IERC2535DiamondCutInternal.sol";
import "forge-std/Script.sol";
import "forge-std/Test.sol";

contract ConstantPriceMonetaryFacetTest is Test {
    QuexDiamond internal diamond;
    IConstantPriceMonetaryFacet internal testObject;

    address private manager = vm.createWallet("manager").addr;

    function setUp() public virtual {
        diamond = new QuexDiamond();
        diamond.init();
        diamond.grantRole(QuexRoles.Manager, manager);

        ConstantPriceMonetaryFacet facet = new ConstantPriceMonetaryFacet();
        IERC2535DiamondCutInternal.FacetCut[] memory cuts = new IERC2535DiamondCutInternal.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](2);

        selectors[0] = ConstantPriceMonetaryFacet.getActionFee.selector;
        selectors[1] = ConstantPriceMonetaryFacet.setActionFee.selector;

        cuts[0] = IERC2535DiamondCutInternal.FacetCut({
            target: address(facet),
            action: IERC2535DiamondCutInternal.FacetCutAction.ADD,
            selectors: selectors
        });

        diamond.diamondCut(cuts, address(0), "");
        testObject = IConstantPriceMonetaryFacet(address(diamond));
    }

    function testFuzz_setActionFee_SetsFee(uint256 fee, uint256 actionId) public {
        vm.prank(manager);
        testObject.setActionFee(fee);

        vm.assertEq(fee, testObject.getActionFee(actionId));
    }

    function test_setActionFee_RevertsIf_CallerIsNotManager() public {
        vm.expectRevert();
        testObject.setActionFee(100);
    }
}
