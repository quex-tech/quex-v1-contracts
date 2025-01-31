// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./TrustDomainPolicyStorage.sol";
import "@solidstate/contracts/access/ownable/OwnableInternal.sol";

interface ITrustDomainPolicyFacet {
    function isInPool(uint256 tdId) external view returns (bool);

    function addToPoll(uint256 tdId) external;

    function removeFromPool(uint256 tdId) external;
}

contract TrustDomainPolicyFacet is ITrustDomainPolicyFacet, OwnableInternal {
    function isInPool(uint256 tdId) external view returns (bool) {
        return TrustDomainPolicyStorage.layout().allowedTDs[tdId] == 1;
    }

    function addToPoll(uint256 tdId) external onlyOwner {
        TrustDomainPolicyStorage.layout().allowedTDs[tdId] = 1;
    }

    function removeFromPool(uint256 tdId) external onlyOwner {
        TrustDomainPolicyStorage.layout().allowedTDs[tdId] = 0;
    }
}
