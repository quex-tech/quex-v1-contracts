// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./IFeedTrustDomainPolicyExtended.sol";

import "./TrustDomainPolicyStorage.sol";
import "@solidstate/contracts/access/ownable/OwnableInternal.sol";

contract FeedTrustDomainPolicyFacet is IFeedTrustDomainPolicyExtended, OwnableInternal {
    function isTDAllowedForFeed(address tdAddress) external view returns (bool) {
        return TrustDomainPolicyStorage.layout().allowedTDs[tdAddress] == 1;
    }

    function allowTDForFeed(address tdAddress) external onlyOwner {
        TrustDomainPolicyStorage.layout().allowedTDs[tdAddress] = 1;
    }

    function disallowTDForFeed(address tdAddress) external onlyOwner {
        TrustDomainPolicyStorage.layout().allowedTDs[tdAddress] = 0;
    }
}
