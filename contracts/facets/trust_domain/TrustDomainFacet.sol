// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./TrustDomainStorage.sol";
import "../../interfaces/core/ITrustDomainRegistry.sol";
import "./QuoteVerifier.sol";

import "@solidstate/contracts/access/ownable/Ownable.sol";

contract TrustDomainFacet is ITrustDomainRegistryExtended, Ownable {
    constructor() {
    }

    function addRootKey(ECKey memory key) external onlyOwner {
        TrustDomainStorage.certificateLayout().rootCA = key;
    }

    function getRootKey() external view returns(ECKey memory) {
        return TrustDomainStorage.certificateLayout().rootCA;
    }

    function addPlatformCAKey(
        uint256 x,
        uint256 y,
        uint256 serial,
        bytes memory notBefore,
        bytes memory extensions,
        uint256 r,
        uint256 s
    ) external {
        QuoteVerifier.ensurePlatformCAKeyIsValid(x, y, serial, notBefore, extensions, r, s);
        // TODO: not_before, not_after decoding
        TrustDomainStorage.certificateLayout().platformCAs[serial] = ECKey(x, y, 0, 0);
    }

    function getPlatformCAKey(uint256 serial) external view returns(ECKey memory) {
        return TrustDomainStorage.certificateLayout().platformCAs[serial];
    }

    function addPCK(
        uint256 x,
        uint256 y,
        uint256 serial,
        bytes memory notBefore,
        bytes memory notAfter,
        bytes memory extensions,
        uint256 authority,
        uint256 r,
        uint256 s
    ) external {
        QuoteVerifier.ensurePCKIsValid(x, y, serial, notBefore, notAfter, extensions, authority, r, s);

        TrustDomainStorage.CertificateLayout storage layout = TrustDomainStorage.certificateLayout();
        // TODO not_before, not_after
        layout.processorPCKs[authority][serial] = ECKey(x, y, 0, 0);
        layout.processorPCKSerials[authority].push(serial);
    }

    function getPCK(uint256 platformSerial, uint256 pckSerial) external view returns (ECKey memory) {
        return TrustDomainStorage.certificateLayout().processorPCKs[platformSerial][pckSerial];
    }

    function revokePCK(uint256 platformSerial, uint256 pckSerial) external onlyOwner {
        delete TrustDomainStorage.certificateLayout().processorPCKs[platformSerial][pckSerial];
    }

    // TODO rewrite such that unneeded items are popped
    function revokePlatformCA(uint256 serial) external onlyOwner {
        TrustDomainStorage.CertificateLayout storage layout = TrustDomainStorage.certificateLayout();
        delete layout.platformCAs[serial];
        uint256 curr_len = layout.processorPCKSerials[serial].length;

        while (curr_len > 0) {
            uint256 pck_serial = layout.processorPCKSerials[serial][curr_len - 1];
            delete layout.processorPCKs[serial][pck_serial];
            layout.processorPCKSerials[serial].pop();
            curr_len -= 1;
        }
    }

    function addQE(
        QEReport memory qeReport,
        uint256 platformSerial,
        uint256 pckSerial,
        uint256 r,
        uint256 s
    ) external returns (uint256 qeId) {
        QuoteVerifier.ensureQEReportIsValid(qeReport, platformSerial, pckSerial, r, s);
        TrustDomainStorage.QELayout storage layout = TrustDomainStorage.qeLayout();

        // TODO: Are all fields needed for storage?
        qeId = layout.qeReportsCounter;
        layout.qeAuthorities[qeId] = TrustDomainStorage.QEAuthority(platformSerial, pckSerial);
        layout.qeReports[qeId] = qeReport;
        layout.qeReportsCounter++;

        return qeId;
    }

    function addTD(
        TDQuote memory tdQuote,
        uint qeId,
        uint256 x,
        uint256 y,
        bytes32 authenticationData,
        uint256 r,
        uint256 s
    ) external returns (address tdAddress) {
        QuoteVerifier.ensureTDQuoteIsValid(tdQuote, qeId, x, y, authenticationData, r, s);
        TrustDomainStorage.TDLayout storage layout = TrustDomainStorage.tdLayout();

        bytes memory publicKey = abi.encodePacked(tdQuote.REPORT_DATA1, tdQuote.REPORT_DATA2);
        tdAddress = _convertPublicKeyToAddress(publicKey);

        // TODO Optimize storage
        layout.tdQuotes[tdAddress] = tdQuote;
        layout.tdToQe[tdAddress] = qeId;
        return tdAddress;
    }

    function isTDValid(address tdAddress) external view returns (bool) {
        // todo: check QE/certs validity?
        // todo: different mapping to reduce read gas cost
        return TrustDomainStorage.tdLayout().tdQuotes[tdAddress].REPORT_DATA1 != 0;
    }

    function getTD(address tdAddress) external view returns (TDQuote memory) {
        return TrustDomainStorage.tdLayout().tdQuotes[tdAddress];
    }

    function getQE(uint256 qeId) external view returns (QEReport memory) {
        return TrustDomainStorage.qeLayout().qeReports[qeId];
    }

    function getQEId(address tdAddress) external view returns (uint256 qeId) {
        return TrustDomainStorage.tdLayout().tdToQe[tdAddress];
    }

    function getQEAuthority(uint256 qeId) external view returns (uint256 platformSerial, uint256 pckSerial) {
        TrustDomainStorage.QEAuthority memory authority = TrustDomainStorage.qeLayout().qeAuthorities[qeId];
        return (authority.platformSerial, authority.pckSerial);
    }

    function _convertPublicKeyToAddress(bytes memory publicKey) private pure returns (address) {
        require(publicKey.length == 64, "Invalid public key length");
        bytes32 hash = keccak256(publicKey);
        return address(uint160(uint256(hash)));
    }
}
