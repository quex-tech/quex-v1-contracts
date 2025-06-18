// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../interfaces/core/ITrustDomainRegistry.sol";
import "./TrustDomainStorage.sol";

contract TrustDomainFacetInitializer {
    function init() external {
        TrustDomainStorage.Layout storage layout = TrustDomainStorage.layout();
        layout.qeReportsCounter = 1;

        layout.rootCA = ECKey(
            5275396427259600295205699346051612009608649108361334488579923812221977961973,
            46845397539833112468023930766933724654059191035252061765541298347349946299284,
            1526899510,
            2524607999
        );
    }
}