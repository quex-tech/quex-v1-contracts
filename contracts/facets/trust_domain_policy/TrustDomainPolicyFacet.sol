// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./TrustDomainPolicyStorage.sol";
import "./ITrustDomainPolicy.sol";

import "@solidstate/contracts/access/ownable/Ownable.sol";

contract TrustDomainPolicyFacet is ITrustDomainPolicy, ITrustDomainPolicyInternal, Ownable {
    function isAllowed(address tdAddress) external view returns (bool) {
        return TrustDomainPolicyStorage.layout().allowedTDs[tdAddress] == 1;
    }

    function allowTD(address tdAddress) external onlyOwner {
        TrustDomainPolicyStorage.layout().allowedTDs[tdAddress] = 1;
    }

    function disallowTD(address tdAddress) external onlyOwner {
        TrustDomainPolicyStorage.layout().allowedTDs[tdAddress] = 0;
    }
}
