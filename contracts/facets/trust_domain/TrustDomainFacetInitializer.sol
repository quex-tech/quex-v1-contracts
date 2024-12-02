// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./ITrustDomainRegistry.sol";
import "./TrustDomainStorage.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";

contract TrustDomainFacetInitializer is ERC165Base {
    function init(address p256VerifierAddress) external {
        TrustDomainStorage.Layout storage layout = TrustDomainStorage.layout();
        layout.p256VerifierAddress = p256VerifierAddress;
        layout.qeReportsCounter = 1;

        _setSupportsInterface(type(ITrustDomainRegistry).interfaceId, true);
        _setSupportsInterface(type(ITrustDomainRegistryExtended).interfaceId, true);
    }
}