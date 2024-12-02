// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./TrustDomainStorage.sol";

contract TrustDomainFacetInitializer {
    function init(address p256VerifierAddress) external {
        TrustDomainStorage.Layout storage layout = TrustDomainStorage.layout();
        layout.p256VerifierAddress = p256VerifierAddress;
        layout.qeReportsCounter = 1;
    }
}