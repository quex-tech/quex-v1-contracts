// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./TrustDomainPolicyStorage.sol";
import "./ITrustDomainPolicy.sol";

import "@solidstate/contracts/access/ownable/Ownable.sol";

contract TrustDomainPolicy is ITrustDomainPolicy, ITrustDomainPolicyInternal, Ownable {
    function isAllowed(uint256 tdId) external view returns (bool) {
        return TrustDomainPolicyStorage.layout().allowedTDs[tdId] == 1;
    }

    function allowTD(uint256 tdId) external onlyOwner {
        TrustDomainPolicyStorage.layout().allowedTDs[tdId] = 1;
    }

    function disallowTD(uint256 tdId) external onlyOwner {
        TrustDomainPolicyStorage.layout().allowedTDs[tdId] = 0;
    }
}
