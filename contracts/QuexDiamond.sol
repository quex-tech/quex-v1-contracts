// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "@solidstate/contracts/proxy/diamond/SolidStateDiamond.sol";

import "./facets/trust_domain/ITrustDomainRegistry.sol";
import "./facets/feed/IFeedRegistry.sol";
import "./facets/request/IRequestRegistry.sol";

contract QuexDiamond is SolidStateDiamond {
    constructor() {
        bytes4[] memory selectors = new bytes4[](20);
        uint256 selectorIndex;

        // register ITrustDomainRegistry

        selectors[selectorIndex++] = ITrustDomainRegistry.addPlatformCAKey.selector;
        selectors[selectorIndex++] = ITrustDomainRegistry.addPCK.selector;
        selectors[selectorIndex++] = ITrustDomainRegistry.addQE.selector;
        selectors[selectorIndex++] = ITrustDomainRegistry.addTD.selector;
        selectors[selectorIndex++] = ITrustDomainRegistry.getPCK.selector;
        selectors[selectorIndex++] = ITrustDomainRegistry.getTD.selector;
        selectors[selectorIndex++] = ITrustDomainRegistry.getQE.selector;
        selectors[selectorIndex++] = ITrustDomainRegistry.getQEId.selector;
        selectors[selectorIndex++] = ITrustDomainRegistry.getQEAuthority.selector;

        _setSupportsInterface(type(ITrustDomainRegistry).interfaceId, true);

        // register ITrustDomainRegistryInternal

        selectors[selectorIndex++] = ITrustDomainRegistryInternal.revokePCK.selector;
        selectors[selectorIndex++] = ITrustDomainRegistryInternal.revokePlatformCA.selector;
        selectors[selectorIndex++] = ITrustDomainRegistryInternal.getSignerAddress.selector;
        
        _setSupportsInterface(type(ITrustDomainRegistryInternal).interfaceId, true);

        // register TrustDomainPolicy

        // TODO

        // register IFeedRegistry

        selectors[selectorIndex++] = IFeedRegistry.addRequest.selector;
        selectors[selectorIndex++] = IFeedRegistry.addPrivatePatch.selector;
        selectors[selectorIndex++] = IFeedRegistry.addJqFilter.selector;
        selectors[selectorIndex++] = IFeedRegistry.addResponseSchema.selector;
        selectors[selectorIndex++] = IFeedRegistry.addFeed.selector;
        selectors[selectorIndex++] = IFeedRegistry.getFeed.selector;

        _setSupportsInterface(type(IFeedRegistry).interfaceId, true);

        // register RequestRegistry

        selectors[selectorIndex++] = IRequestRegistry.sendRequest.selector;

        _setSupportsInterface(type(IRequestRegistry).interfaceId, true);

        // register RequestRegistry

        selectors[selectorIndex++] = IRequestRegistryInternal.processResponse.selector;

        _setSupportsInterface(type(IRequestRegistryInternal).interfaceId, true);

        // diamond cut

        FacetCut[] memory facetCuts = new FacetCut[](1);

        facetCuts[0] = FacetCut({
            target: address(this),
            action: FacetCutAction.ADD,
            selectors: selectors
        });

        _diamondCut(facetCuts, address(0), '');
    }
}