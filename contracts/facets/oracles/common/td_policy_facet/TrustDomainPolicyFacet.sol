// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./TrustDomainPolicyStorage.sol";
import "@solidstate/contracts/access/ownable/Ownable.sol";

contract TrustDomainPolicyFacet is Ownable {
    function isInPool(address tdAddress) external view returns (bool) {
        return TrustDomainPolicyStorage.layout().allowedTDs[tdAddress] == 1;
    }

    function addToPoll(address tdAddress) external onlyOwner {
        TrustDomainPolicyStorage.layout().allowedTDs[tdAddress] = 1;
    }

    function removeFromPool(address tdAddress) external onlyOwner {
        TrustDomainPolicyStorage.layout().allowedTDs[tdAddress] = 0;
    }
}