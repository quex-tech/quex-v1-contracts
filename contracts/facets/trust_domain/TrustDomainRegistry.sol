// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./TrustDomainStorage.sol";
import "./IV1TrustDomainRegistry.sol";
import "./QuoteVerifier.sol";

import "@solidstate/contracts/access/ownable/Ownable.sol";

contract TrustDomainRegistry is ITrustDomainRegistry, Ownable {
    constructor(address) {
        TrustDomainStorage.Layout storage layout = TrustDomainStorage.layout();
        layout.qeReportsCounter = 1;
        layout.tdQuotesCounter = 1;
    }

    function addRootKey(TrustDomainStorage.ECKey memory key) public onlyOwner {
        TrustDomainStorage.layout().rootCA = key;
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
        TrustDomainStorage.layout().platformCAs[serial] = TrustDomainStorage.ECKey(x, y, 0, 0);
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
        QuoteVerifier.ensurePCKIsValid(x,y,serial, notBefore, notAfter, extensions, authority, r,s);

        TrustDomainStorage.Layout storage layout = TrustDomainStorage.layout();
        // TODO not_before, not_after
        layout.processorPCKs[authority][serial] = TrustDomainStorage.ECKey(x,y,0,0);
        layout.processorPCKserials[authority].push(serial);

    }

    function getPCK(
        uint256 platformSerial,
        uint256 pckSerial
    ) external view returns (TrustDomainStorage.ECKey memory) {}

    function revokePCK(uint256 platformSerial, uint256 pckSerial) external onlyOwner {
        delete TrustDomainStorage.layout().processorPCKs[platformSerial][pckSerial];
    }

    // TODO rewrite such that unneeded items are popped
    function revokePlatformCA(uint256 serial) external onlyOwner {
        TrustDomainStorage.Layout storage layout = TrustDomainStorage.layout();
        delete layout.platformCAs[serial];
        uint256 curr_len = layout.processorPCKserials[serial].length;

        while(curr_len > 0) {
            uint256 pck_serial = layout.processorPCKserials[serial][curr_len - 1];
            delete layout.processorPCKs[serial][pck_serial];
            layout.processorPCKserials[serial].pop();
            curr_len -= 1;
        }}

    function addQE(
        TrustDomainStorage.QEReport memory qeReport,
        uint256 platformSerial,
        uint256 pckSerial,
        uint256 r,
        uint256 s
    ) external returns (uint256 qeId) {
        QuoteVerifier.ensureQEReportIsValid(qeReport, platformSerial, pckSerial, r, s);
        TrustDomainStorage.Layout storage layout = TrustDomainStorage.layout();

        // TODO: Are all fields needed for storage?
        qeId = layout.qeReportsCounter;
        layout.qeAuthorities[qeId] = TrustDomainStorage.QEAuthority(platformSerial, pckSerial);
        layout.qeReports[qeId] = qeReport;
        layout.qeReportsCounter++;

        return qeId;
    }

    function addTD(
        TrustDomainStorage.TDQuote memory tdQuote,
        uint qeId,
        uint256 x,
        uint256 y,
        bytes32 authenticationData,
        uint256 r,
        uint256 s
    ) external returns (uint256 tdId) {
        QuoteVerifier.ensureTDQuoteIsValid(tdQuote, qeId, x, y, authenticationData, r, s);
        TrustDomainStorage.Layout storage layout = TrustDomainStorage.layout();

        bytes memory publicKey = abi.encodePacked(tdQuote.REPORT_DATA1, tdQuote.REPORT_DATA2);
        address signerAddress = _convertPublicKeyToAddress(publicKey);

        // TODO Optimize storage
        tdId = layout.tdQuotesCounter;
        layout.tdQuotes[tdId] = tdQuote;
        layout.tdToQe[tdId] = qeId;
        layout.signerAddresses[tdId] = signerAddress;
        layout.tdQuotesCounter++;
        return tdId;
    }

    function getTD(uint256 tdId) external view returns (TrustDomainStorage.TDQuote memory) {}

    function getQE(uint256 qeId) external view returns (TrustDomainStorage.QEReport memory) {}

    function getQEId(uint256 tdId) external view returns (uint256 qeId) {}

    function getQEAuthority(uint256 qeId) external view returns (uint256 platformSerial, uint256 pckSerial) {}

    function _convertPublicKeyToAddress(bytes memory publicKey) private pure returns (address) {
        require(publicKey.length == 64, "Invalid public key length");
        bytes32 hash = keccak256(publicKey);
        return address(uint160(uint256(hash)));
    }
}
