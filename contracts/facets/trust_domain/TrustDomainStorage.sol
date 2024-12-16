// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./TrustDomainModels.sol";

library TrustDomainStorage {
    struct QEAuthority {
        uint256 platformSerial;
        uint256 pckSerial;
    }

    struct CertificateLayout {
        ECKey rootCA;
        mapping(uint256 => ECKey) platformCAs;
        mapping(uint256 => mapping(uint256 => ECKey)) processorPCKs;
        mapping(uint256 => uint256[]) processorPCKSerials;
    }

    struct QELayout {
        mapping(uint256 => QEReport) qeReports;
        mapping(uint256 => QEAuthority) qeAuthorities;
        uint256 qeReportsCounter;
    }

    struct TDLayout {
        mapping(address => TDQuote) tdQuotes;
        mapping(address => uint256) tdToQe;
    }

    bytes32 internal constant CERT_STORAGE_SLOT = keccak256("quex.contracts.storage.TrustDomain.Certificate");
    bytes32 internal constant QE_STORAGE_SLOT = keccak256("quex.contracts.storage.TrustDomain.QE");
    bytes32 internal constant TD_STORAGE_SLOT = keccak256("quex.contracts.storage.TrustDomain.TD");

    function certificateLayout() internal pure returns (CertificateLayout storage l) {
        bytes32 slot = CERT_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function qeLayout() internal pure returns (QELayout storage l) {
        bytes32 slot = QE_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
    function tdLayout() internal pure returns (TDLayout storage l) {
        bytes32 slot = TD_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
