// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {ECKey, QEReport, TDQuote} from "../../interfaces/core/ITrustDomainRegistry.sol";

library TrustDomainStorage {
    struct QEAuthority {
        uint256 platformSerial;
        uint256 pckSerial;
    }

    struct Layout {
        ECKey rootCA;
        mapping(uint256 => ECKey) platformCAs;
        mapping(uint256 => mapping(uint256 => ECKey)) processorPCKs;
        uint256 qeReportsCounter;
        mapping(uint256 => QEReport) qeReports;
        mapping(uint256 => QEAuthority) qeAuthorities;
        mapping(uint256 => TDQuote) tdQuotes;
        mapping(uint256 => uint256) tdToQe;
        mapping(uint256 => address) tdSignerAddress;
        mapping(uint256 => uint256) tdValidityEnd;
        mapping(uint256 => uint256) pckCounterByPlatformCA;
        mapping(uint256 => mapping(uint256 => uint256)) qeCounterByProcessorPCK;
        mapping(uint256 => uint256) tdCounterByQE;
        mapping(bytes16 => uint256) allowedTeeTcbSvn;
        mapping(bytes16 => uint256) teeTcbSvnTDCounter;
        mapping(bytes16 => uint256) allowedCpuSvn;
        mapping(bytes16 => uint256) cpuSvnQECounter;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("quex.contracts.storage.TrustDomain");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
        return l;
    }
}