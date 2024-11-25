// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./TrustDomainModels.sol";

library TrustDomainStorage {
    struct QEAuthority {
        uint256 platformSerial;
        uint256 pckSerial;
    }

    struct Layout {
        address p256VerifierAddress;

        // certs 
        ECKey rootCA;
        mapping(uint256 => ECKey) platformCAs;
        mapping(uint256 => mapping(uint256 => ECKey)) processorPCKs;

        // qoute enclave
        mapping(uint256 => uint256[]) processorPCKserials;
        mapping(uint256 => QEReport) qeReports;
        mapping(uint256 => QEAuthority) qeAuthorities;
        uint256 qeReportsCounter;

        // trust domain
        mapping(address => TDQuote) tdQuotes;
        mapping(address => uint256) tdToQe;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("quex.contracts.storage.TrustDomain");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
