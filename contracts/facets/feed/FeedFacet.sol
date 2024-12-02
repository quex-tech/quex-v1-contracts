// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {FeedRegistryFacet} from "./feed_registry/FeedRegistryFacet.sol";
import {FeedRequestRegistryFacet} from "./request_registry/FeedRequestRegistryFacet.sol";
import {FeedTrustDomainPolicyFacet} from "./trust_domain_policy/FeedTrustDomainPolicyFacet.sol";

contract FeedFacet is FeedRegistryFacet, FeedRequestRegistryFacet, FeedTrustDomainPolicyFacet {
}