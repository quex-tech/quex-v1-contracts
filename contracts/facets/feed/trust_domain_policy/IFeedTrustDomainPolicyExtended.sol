// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./IFeedTrustDomainPolicy.sol";

interface IFeedTrustDomainPolicyExtended is IFeedTrustDomainPolicy {
    function allowTDForFeed(address tdAddress) external;

    function disallowTDForFeed(address tdAddress) external;
}
