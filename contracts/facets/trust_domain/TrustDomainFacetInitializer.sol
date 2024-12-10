// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./ITrustDomainRegistry.sol";
import "./TrustDomainStorage.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";

contract TrustDomainFacetInitializer {
    function init() external {
        TrustDomainStorage.Layout storage layout = TrustDomainStorage.layout();
        layout.qeReportsCounter = 1;
    }
}