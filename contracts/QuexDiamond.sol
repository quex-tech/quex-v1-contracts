// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "@solidstate/contracts/proxy/diamond/SolidStateDiamond.sol";

contract QuexDiamond is
    DiamondBase,
    DiamondFallback,
    DiamondReadable,
    DiamondWritable,
    SafeOwnable
{
    constructor() {
        bytes4[] memory selectors = new bytes4[](11);
        uint256 selectorIndex;

        // register DiamondFallback

        selectors[selectorIndex++] = IDiamondFallback
            .getFallbackAddress
            .selector;
        selectors[selectorIndex++] = IDiamondFallback
            .setFallbackAddress
            .selector;

        // register DiamondWritable

        selectors[selectorIndex++] = IERC2535DiamondCut.diamondCut.selector;

        // register DiamondReadable

        selectors[selectorIndex++] = IERC2535DiamondLoupe.facets.selector;
        selectors[selectorIndex++] = IERC2535DiamondLoupe
            .facetFunctionSelectors
            .selector;
        selectors[selectorIndex++] = IERC2535DiamondLoupe
            .facetAddresses
            .selector;
        selectors[selectorIndex++] = IERC2535DiamondLoupe.facetAddress.selector;

        // register SafeOwnable

        selectors[selectorIndex++] = Ownable.owner.selector;
        selectors[selectorIndex++] = SafeOwnable.nomineeOwner.selector;
        selectors[selectorIndex++] = Ownable.transferOwnership.selector;
        selectors[selectorIndex++] = SafeOwnable.acceptOwnership.selector;

        // diamond cut

        FacetCut[] memory facetCuts = new FacetCut[](1);

        facetCuts[0] = FacetCut({
            target: address(this),
            action: FacetCutAction.ADD,
            selectors: selectors
        });

        _diamondCut(facetCuts, address(0), '');

        // set owner

        _setOwner(msg.sender);
    }

    receive() external payable {}

    function _transferOwnership(
        address account
    ) internal virtual override(OwnableInternal, SafeOwnable) {
        super._transferOwnership(account);
    }

    /**
     * @inheritdoc DiamondFallback
     */
    function _getImplementation()
        internal
        view
        override(DiamondBase, DiamondFallback)
        returns (address implementation)
    {
        implementation = super._getImplementation();
    }
}
