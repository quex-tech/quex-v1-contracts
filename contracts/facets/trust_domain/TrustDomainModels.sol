// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

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
