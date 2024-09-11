// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;
import "../interfaces/IV1QuoteVerifier.sol";
import "../interfaces/IV1CertificateVerifier.sol";
import "hardhat/console.sol";

bytes constant TD_HEADER_PREAMBLE = hex"040002008100000000000000939A7233F79C4CA9940A0DB3957F0607";

struct QEAuthority {
    uint256 platform_serial;
    uint256 pck_serial;
}

contract V1QuoteVerifier is IV1QuoteVerifier {
    address CERTIFICATE_VERIFIER;
    address P256_VERIFIER;
    mapping (uint256 => QEReport) qe_reports;
    mapping (uint256 => TDQuote) td_quotes;
    mapping (uint256 => uint256) td_to_qe;
    mapping (uint256 => QEAuthority) qe_authorities;
    uint256 qe_reports_counter;
    uint256 td_quotes_counter;

    constructor (address _p256_verifier, address _cert_verifier) {
        CERTIFICATE_VERIFIER = _cert_verifier;
        P256_VERIFIER  = _p256_verifier;
        qe_reports_counter = 1;
        td_quotes_counter = 1;
    }

    function verifySignatureAllowMalleability(
        bytes32 message_hash,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y
    ) internal view returns (bool) {
        bytes memory args = abi.encode(message_hash, r, s, x, y);
        (bool success, bytes memory ret) = P256_VERIFIER.staticcall(args);
        assert(success); // never reverts, always returns 0 or 1

        return abi.decode(ret, (uint256)) == 1;
    }

    function addQE(
        QEReport memory qe_report, 
        uint256 platform_serial,
        uint256 pck_serial,
        uint256 r,
        uint256 s
    ) public returns (uint qe_id)
    {
        ECKey memory authority_key = IV1CertificateVerifier(CERTIFICATE_VERIFIER).getPCK(platform_serial, pck_serial);
        require(authority_key.x != 0);
        bytes28 reserved28;
        bytes32 reserved32;
        bytes memory report_body1 = bytes.concat(
            qe_report.CPUSVN,
            qe_report.MISCSELECT,
            reserved28,
            qe_report.attributes,
            qe_report.MRENCLAVE,
            reserved32,
            qe_report.MRSIGNER
        );
        bytes memory report_body = bytes.concat(
            report_body1,
            reserved32, reserved32, reserved32,
            qe_report.ISVProdID,
            qe_report.ISVSVN,
            reserved32, reserved28,
            qe_report.REPORT_DATA1,
            qe_report.REPORT_DATA2
        );
        bytes32 hash = sha256(report_body);
        require(verifySignatureAllowMalleability(
            hash,
            r,
            s,
            authority_key.x,
            authority_key.y
        ));
        // TODO: Are all fields needed for storage?
        qe_authorities[qe_reports_counter] = QEAuthority(platform_serial, pck_serial);
        qe_reports[qe_reports_counter] = qe_report;
        qe_reports_counter++;
        return qe_reports_counter - 1;
    }

    function addTD(
        TDQuote memory td_quote, 
        uint qe_id,
        uint256 x,
        uint256 y,
        bytes32 authentication_data,
        uint256 r,
        uint256 s
    ) public returns (uint256 td_id) {
        bytes32 qe_report_data = sha256(bytes.concat(
            bytes32(x),
            bytes32(y),
            authentication_data
        ));
        console.logBytes32(qe_report_data);
        require(qe_reports[qe_id].REPORT_DATA1 == qe_report_data);

        bytes memory td_header = bytes.concat(
            TD_HEADER_PREAMBLE,
            td_quote.USER_DATA
        );
        bytes memory body1 = bytes.concat(
            td_quote.TEE_TCB_SVN,
            td_quote.MRSEAM,
            td_quote.MRSIGNERSEAM,
            td_quote.SEAMATTRIBUTES,
            td_quote.TDATTRIBUTES,
            td_quote.XFAM,
            td_quote.MRTD,
            td_quote.MRCONFIGD
        );
        bytes memory body_bin = bytes.concat(
            body1,
            td_quote.MROWNER,
            td_quote.MROWNERCONFIG,
            td_quote.RTMR0,
            td_quote.RTMR1,
            td_quote.RTMR2,
            td_quote.RTMR3,
            td_quote.REPORT_DATA1,
            td_quote.REPORT_DATA2
        );

        bytes memory report = bytes.concat(td_header, body_bin);
        bytes32 hash = sha256(report);
        require(verifySignatureAllowMalleability(
            hash,
            r,
            s,
            x,
            y
        ));
        // TODO Optimize storage
        td_quotes[td_quotes_counter] = td_quote;
        td_to_qe[td_quotes_counter] = qe_id;
        td_quotes_counter++;
        return td_quotes_counter - 1;
    }

    function getTD(uint256 td_id) public view returns (TDQuote memory) {
        return td_quotes[td_id];
    }

    function getQE(uint256 qe_id) public view returns (QEReport memory) {
        return qe_reports[qe_id];
    }

    function getQEID(uint256 td_id) public view returns (uint256 qe_id) {
        return td_to_qe[td_id];
    }

    function getQEAuthority(uint256 qe_id) public view returns (uint256 platform_serial, uint256 pck_serial) {
        return (qe_authorities[qe_id].platform_serial, qe_authorities[qe_id].pck_serial);
    }
}
