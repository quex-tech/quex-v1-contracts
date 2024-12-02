// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../trust_domain/ITrustDomainRegistry.sol";
import "./feed_registry/IFeedRegistry.sol";
import "./request_registry/IFeedRequestRegistry.sol";
import "./request_registry/IFeedRequestRegistryExtended.sol";
import "./trust_domain_policy/IFeedTrustDomainPolicy.sol";
import "./trust_domain_policy/IFeedTrustDomainPolicyExtended.sol";

import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";

contract FeedFacetInitializer is ERC165Base {
    function init() external {
        _setSupportsInterface(type(IFeedRegistry).interfaceId, true);
        _setSupportsInterface(type(IFeedRequestRegistry).interfaceId, true);
        _setSupportsInterface(type(IFeedTrustDomainPolicy).interfaceId, true);
    }
}