// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./TrustDomainStorage.sol";
import {IP256Verifier} from "../../interfaces/core/IP256Verifier.sol";

library QuoteVerifier {
    error RootCA_Expired();
    error InvalidPlatformCertificate();
    error InvalidPCK();
    error PlatformCA_NotFound();
    error PlatformCA_Expired();
    error PCKNotFound();
    error QEReport_InvalidSignature();
    error TDReport_InvalidQuote();
    error TDReport_InvalidSignature();
    error TDReport_UnsafeAttributes();   
    error TDReport_InvalidTeeTcbSvn();
    error QEReport_InvalidCpuSvn();

    bytes private constant TD_HEADER_PREAMBLE = hex"040002008100000000000000939A7233F79C4CA9940A0DB3957F0607";

    // root cert template
    bytes private constant ri1 = hex"30";
    bytes private constant ri3 = hex"a00302010202";
    bytes private constant ri7 =
        hex"300a06082a8648ce3d0403023068311a301806035504030c11496e74656c2053475820526f6f74204341311a3018060355040a0c11496e74656c20436f72706f726174696f6e3114301206035504070c0b53616e746120436c617261310b300906035504080c024341310b3009060355040613025553301e170d";
    bytes private constant ri11 =
        hex"170d3333303532313130353031305a30703122302006035504030c19496e74656c205347582050434b20506c6174666f726d204341311a3018060355040a0c11496e74656c20436f72706f726174696f6e3114301206035504070c0b53616e746120436c617261310b300906035504080c024341310b30090603550406130255533059301306072a8648ce3d020106082a8648ce3d03010703420004";
    bytes private constant ri16 = hex"a3";
    uint256 private constant rbase_len = 349;

    // platform cert template
    bytes private constant pi1 = hex"30";
    bytes private constant pi3 = hex"a00302010202";
    bytes private constant pi7 =
        hex"300a06082a8648ce3d04030230703122302006035504030c19496e74656c205347582050434b20506c6174666f726d204341311a3018060355040a0c11496e74656c20436f72706f726174696f6e3114301206035504070c0b53616e746120436c617261310b300906035504080c024341310b3009060355040613025553301e170d";
    bytes private constant pi11 = hex"170d";
    bytes private constant pi13 =
        hex"30703122302006035504030c19496e74656c205347582050434b204365727469666963617465311a3018060355040a0c11496e74656c20436f72706f726174696f6e3114301206035504070c0b53616e746120436c617261310b300906035504080c024341310b30090603550406130255533059301306072a8648ce3d020106082a8648ce3d03010703420004";
    bytes private constant pi16 = hex"a3";
    uint256 private constant pbase_len = 344;

    function ensureQEReportIsValid(
        QEReport memory qeReport,
        uint256 platformSerial,
        uint256 pckSerial,
        uint256 r,
        uint256 s
    ) internal view {
        TrustDomainStorage.Layout storage layout = TrustDomainStorage.layout();
        if (layout.allowedCpuSvn[qeReport.CPUSVN] == 0) {
            revert QEReport_InvalidCpuSvn();
        }

        ECKey memory authorityKey = layout.processorPCKs[platformSerial][pckSerial];
        if (authorityKey.x == 0) {
            revert PCKNotFound();
        }
        bytes28 reserved28;
        bytes32 reserved32;

        bytes memory reportBody1 = bytes.concat(
            qeReport.CPUSVN,
            qeReport.MISCSELECT,
            reserved28,
            qeReport.attributes,
            qeReport.MRENCLAVE,
            reserved32,
            qeReport.MRSIGNER
        );

        bytes memory reportBody = bytes.concat(
            reportBody1,
            reserved32,
            reserved32,
            reserved32,
            qeReport.ISVProdID,
            qeReport.ISVSVN,
            reserved32,
            reserved28,
            qeReport.REPORT_DATA1,
            qeReport.REPORT_DATA2
        );
        bytes32 hash = sha256(reportBody);

        if (!_verifySignatureAllowMalleability(hash, r, s, authorityKey.x, authorityKey.y)) {
            revert QEReport_InvalidSignature();
        }
    }

    function ensureTDQuoteIsValid(
        TDQuote memory tdQuote,
        uint qeId,
        uint256 x,
        uint256 y,
        bytes32 authenticationData,
        uint256 r,
        uint256 s
    ) internal view {
        TrustDomainStorage.Layout storage layout = TrustDomainStorage.layout();

        if (layout.allowedTeeTcbSvn[tdQuote.TEE_TCB_SVN] == 0) {
            revert TDReport_InvalidTeeTcbSvn();
        }

        bytes32 qeReportData = sha256(bytes.concat(bytes32(x), bytes32(y), authenticationData));
        if (layout.qeReports[qeId].REPORT_DATA1 != qeReportData) { 
            revert TDReport_InvalidQuote();
        }

        bytes memory tdHeader = bytes.concat(TD_HEADER_PREAMBLE, tdQuote.USER_DATA);
        bytes memory quoteBody1 = bytes.concat(
            tdQuote.TEE_TCB_SVN,
            tdQuote.MRSEAM,
            tdQuote.MRSIGNERSEAM,
            tdQuote.SEAMATTRIBUTES,
            tdQuote.TDATTRIBUTES,
            tdQuote.XFAM,
            tdQuote.MRTD,
            tdQuote.MRCONFIGID
        );
        bytes memory quoteBody = bytes.concat(
            quoteBody1,
            tdQuote.MROWNER,
            tdQuote.MROWNERCONFIG,
            tdQuote.RTMR0,
            tdQuote.RTMR1,
            tdQuote.RTMR2,
            tdQuote.RTMR3,
            tdQuote.REPORT_DATA1,
            tdQuote.REPORT_DATA2
        );

        bytes memory report = bytes.concat(tdHeader, quoteBody);
        bytes32 hash = sha256(report);

        if (!_verifySignatureAllowMalleability(hash, r, s, x, y)) {
            revert TDReport_InvalidSignature();
        }
    }

    function ensurePlatformCAKeyIsValid(
        uint256 x,
        uint256 y,
        uint256 serial,
        bytes memory notBefore,
        bytes memory extensions,
        uint256 r,
        uint256 s
    ) internal view {
        ECKey memory rootCA = TrustDomainStorage.layout().rootCA;
        if (rootCA.notAfter < block.timestamp) {
            revert RootCA_Expired();
        }

        bytes32 hash = _rootCertBodyHash(_uintToBytesDER(serial), notBefore, x, y, extensions);

        if (!_verifySignatureAllowMalleability(hash, r, s, rootCA.x, rootCA.y)) {
            revert InvalidPlatformCertificate();
        }
    }

    function ensurePCKIsValid(
        uint256 x,
        uint256 y,
        uint256 serial,
        bytes memory notBefore,
        bytes memory notAfter,
        bytes memory extensions,
        uint256 authority,
        uint256 r,
        uint256 s
    ) internal view {
        ECKey memory authorityKey = TrustDomainStorage.layout().platformCAs[authority];
        if (authorityKey.x == 0) {
            revert PlatformCA_NotFound();
        }
        if (authorityKey.notAfter < block.timestamp) {
            revert PlatformCA_Expired();
        }

        bytes32 hash = _platformCertBodyHash(_uintToBytesDER(serial), notBefore, notAfter, x, y, extensions);

        if (!_verifySignatureAllowMalleability(hash, r, s, authorityKey.x, authorityKey.y)) {
            revert InvalidPCK();
        }
    }

    function ensureTDAttributesSafe(
        TDQuote memory tdQuote
    ) internal pure {
        // mask & value == 0: bits 0-27, 29, and 32-62 should be zero
        uint64 mask = 0xFFFFFF2FFFFFFF7F;
        
        uint64 attributes = uint64(tdQuote.TDATTRIBUTES);

        if ((attributes & mask) != 0) {
            revert TDReport_UnsafeAttributes();
        }
    }

    function _verifySignatureAllowMalleability(
        bytes32 messageHash,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y
    ) internal view returns (bool) {
        return IP256Verifier(address(this)).ecdsa_verify(messageHash, r, s, [x, y]);
    }

    function _rootCertBodyHash(
        bytes memory serial,
        bytes memory notBefore,
        uint256 x,
        uint256 y,
        bytes memory extensions
    ) private pure returns (bytes32) {
        bytes memory i17 = _encodeLengthDER(extensions.length);
        bytes memory i5 = _encodeLengthDER(serial.length);
        bytes memory i2 = _encodeLengthDER(
            rbase_len + i17.length + i5.length + extensions.length + serial.length + notBefore.length
        );
        return
            sha256(
                bytes.concat(
                    ri1,
                    i2,
                    ri3,
                    i5,
                    serial,
                    ri7,
                    notBefore,
                    ri11,
                    bytes32(x),
                    bytes32(y),
                    ri16,
                    i17,
                    extensions
                )
            );
    }

    function _platformCertBodyHash(
        bytes memory serial,
        bytes memory notBefore,
        bytes memory notAfter,
        uint256 x,
        uint256 y,
        bytes memory extensions
    ) private pure returns (bytes32) {
        bytes memory i17 = _encodeLengthDER(extensions.length);
        bytes memory i5 = _encodeLengthDER(serial.length);
        bytes memory i2 = _encodeLengthDER(
            pbase_len + i17.length + i5.length + extensions.length + serial.length + notBefore.length + notAfter.length
        );
        bytes memory part_sum = bytes.concat(pi1, i2, pi3, i5, serial, pi7, notBefore, pi11, notAfter);
        return sha256(bytes.concat(part_sum, pi13, bytes32(x), bytes32(y), pi16, i17, extensions));
    }

    function _encodeLengthDER(uint256 n) internal pure returns (bytes memory) {
        if (n < 127) {
            return abi.encodePacked(uint8(n));
        } else {
            bytes memory nb = abi.encodePacked(n);
            uint8 i = 0;
            while (nb[i] == 0x00) {
                i++;
            }
            return bytes.concat(bytes1((32 - i) | 0x80), _tail(nb, i));
        }
    }

    function _uintToBytesDER(uint256 n) private pure returns (bytes memory) {
        require(
            n < 0x8000000000000000000000000000000000000000000000000000000000000000,
            "Can only encode small integers"
        );
        if (n == 0) {
            return hex"0000";
        } else {
            bytes memory b = abi.encodePacked(n);
            uint i = 0;
            while (b[i] == 0) {
                i++;
            }
            if ((b[i] & 0x80) != 0) {
                i--;
            }
            return _tail(b, i);
        }
    }

    function _tail(bytes memory data, uint256 startIndex) internal pure returns (bytes memory tail) {
        require(startIndex < data.length, "Start index out of bounds");

        assembly {
            tail := mload(0x40)
            let length := sub(mload(data), startIndex)

            mstore(tail, length)

            let src := add(add(data, 0x20), startIndex)
            let dest := add(tail, 0x20)

            for { let i := 0 } lt(i, length) { i := add(i, 0x20) } {
                mstore(add(dest, i), mload(add(src, i)))
            }

            mstore(0x40, add(dest, and(add(length, 0x1f), not(0x1f))))
        }
    }
}
