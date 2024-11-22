// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

library TrustDomainStorage {
    struct ECKey {
        uint256 x;
        uint256 y;
        uint256 notBefore;
        uint256 notAfter;
    }

    struct QEReport {
        bytes16 CPUSVN;
        bytes4 MISCSELECT;
        bytes16 attributes;
        bytes MRENCLAVE;
        bytes32 MRSIGNER;
        bytes2 ISVProdID;
        bytes2 ISVSVN;
        bytes32 REPORT_DATA1;
        bytes32 REPORT_DATA2;
    }

    struct TDQuote {
        bytes20 USER_DATA;
        bytes16 TEE_TCB_SVN;
        bytes MRSEAM;
        bytes MRSIGNERSEAM;
        bytes8 SEAMATTRIBUTES;
        bytes8 TDATTRIBUTES;
        bytes8 XFAM;
        bytes MRTD;
        bytes MRCONFIGID;
        bytes MROWNER;
        bytes MROWNERCONFIG;
        bytes RTMR0;
        bytes RTMR1;
        bytes RTMR2;
        bytes RTMR3;
        bytes32 REPORT_DATA1;
        bytes32 REPORT_DATA2;
    }

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
