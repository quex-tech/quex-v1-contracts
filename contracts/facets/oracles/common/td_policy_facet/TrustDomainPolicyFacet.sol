// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../../../QuexRoles.sol";
import "./TrustDomainPolicyStorage.sol";
import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";

interface ITrustDomainPolicyFacet {
    function isInPool(uint256 tdId) external view returns (bool);

    function addToPool(uint256 tdId) external;

    function removeFromPool(uint256 tdId) external;
}

contract TrustDomainPolicyFacet is ITrustDomainPolicyFacet, AccessControlInternal {
    function isInPool(uint256 tdId) external view returns (bool) {
        return TrustDomainPolicyStorage.layout().allowedTDs[tdId] == 1;
    }

    function addToPool(uint256 tdId) external onlyRole(QuexRoles.Manager) {
        TrustDomainPolicyStorage.layout().allowedTDs[tdId] = 1;
    }

    function removeFromPool(uint256 tdId) external onlyRole(QuexRoles.Manager) {
        TrustDomainPolicyStorage.layout().allowedTDs[tdId] = 0;
    }
}
