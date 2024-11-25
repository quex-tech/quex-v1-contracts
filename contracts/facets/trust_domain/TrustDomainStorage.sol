// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./TrustDomainModels.sol";

library TrustDomainStorage {
    struct QEAuthority {
        uint256 platform_serial;
        uint256 pck_serial;
    }

    struct Layout {
        address p256VerifierAddress;
        ECKey rootCA;
        mapping(uint256 => ECKey) platformCAs;
        mapping(uint256 => mapping(uint256 => ECKey)) processorPCKs;
        mapping(uint256 => uint256[]) processorPCKserials;
        mapping(uint256 => address) signerAddresses;
        mapping(uint256 => QEReport) qeReports;
        mapping(uint256 => TDQuote) tdQuotes;
        mapping(uint256 => uint256) tdToQe;
        mapping(uint256 => QEAuthority) qeAuthorities;
        uint256 qeReportsCounter;
        uint256 tdQuotesCounter;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("quex.contracts.storage.TrustDomain");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
