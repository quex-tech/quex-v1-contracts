// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./TrustDomainStorage.sol";
import "../../interfaces/core/ITrustDomainRegistry.sol";
import "./QuoteVerifier.sol";

import "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import {DateTimeLib} from "solady/src/utils/DateTimeLib.sol";

contract TrustDomainFacet is ITrustDomainRegistryExtended, OwnableInternal {
    error Certificate_WrongValidityPeriod();
    error PlatformCARevocation_PCKsExist();
    error PCKRevocation_QEExist();
    error QERevocation_TDExist();

    function getRootKey() external view returns(ECKey memory) {
        return TrustDomainStorage.layout().rootCA;
    }

    function addPlatformCAKey(
        uint256 x,
        uint256 y,
        uint256 serial,
        bytes memory notBefore,
        bytes memory notAfter,
        bytes memory extensions,
        uint256 r,
        uint256 s
    ) external {
        uint256 notBeforeTimestamp = _fromDERToTimestamp(notBefore);
        uint256 notAfterTimestamp = _fromDERToTimestamp(notAfter);
        if (notBeforeTimestamp > block.timestamp || notAfterTimestamp < block.timestamp) {
            revert Certificate_WrongValidityPeriod();
        }

        QuoteVerifier.ensurePlatformCAKeyIsValid(x, y, serial, notBefore, extensions, r, s);
        TrustDomainStorage.layout().platformCAs[serial] = ECKey(x, y, _fromDERToTimestamp(notBefore), _fromDERToTimestamp(notAfter));

        emit PlatformCAAdded(serial);
    }

    function getPlatformCAKey(uint256 serial) external view returns(ECKey memory) {
        return TrustDomainStorage.layout().platformCAs[serial];
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
        uint256 notBeforeTimestamp = _fromDERToTimestamp(notBefore);
        uint256 notAfterTimestamp = _fromDERToTimestamp(notAfter);
        if (notBeforeTimestamp > block.timestamp || notAfterTimestamp < block.timestamp) {
            revert Certificate_WrongValidityPeriod();
        }

        QuoteVerifier.ensurePCKIsValid(x, y, serial, notBefore, notAfter, extensions, authority, r, s);

        TrustDomainStorage.Layout storage layout = TrustDomainStorage.layout();
        layout.processorPCKs[authority][serial] = ECKey(x, y, notBeforeTimestamp, notAfterTimestamp);
        layout.pckCounterByPlatformCA[authority]++;

        emit PCKAdded(authority, serial);
    }

    function getPCK(uint256 platformSerial, uint256 pckSerial) external view returns (ECKey memory) {
        return TrustDomainStorage.layout().processorPCKs[platformSerial][pckSerial];
    }

    function addQE(
        QEReport memory qeReport,
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
        layout.qeCounterByProcessorPCK[platformSerial][pckSerial]++;

        emit QEReportAdded(qeId);

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
    ) external returns (uint256 tdId) {
        QuoteVerifier.ensureTDIsNotInDebugMode(tdQuote);
        QuoteVerifier.ensureTDQuoteIsValid(tdQuote, qeId, x, y, authenticationData, r, s);
        TrustDomainStorage.Layout storage layout = TrustDomainStorage.layout();

        tdId = _calculateTDId(tdQuote);

        bytes memory publicKey = abi.encodePacked(tdQuote.REPORT_DATA1, tdQuote.REPORT_DATA2);
        address tdAddress = _convertPublicKeyToAddress(publicKey);

        // Get certificate chain validity timestamps
        TrustDomainStorage.QEAuthority memory authority = layout.qeAuthorities[qeId];
        ECKey memory rootCA = layout.rootCA;
        ECKey memory platformCA = layout.platformCAs[authority.platformSerial];
        ECKey memory pck = layout.processorPCKs[authority.platformSerial][authority.pckSerial];

        // Find minimum validity timestamp
        uint256 minValidity = rootCA.notAfter;
        if (platformCA.notAfter < minValidity) minValidity = platformCA.notAfter;
        if (pck.notAfter < minValidity) minValidity = pck.notAfter;

        // TODO Optimize storage
        layout.tdQuotes[tdId] = tdQuote;
        layout.tdToQe[tdId] = qeId;
        layout.tdSignerAddress[tdId] = tdAddress;
        layout.tdValidityEnd[tdId] = minValidity;
        layout.tdCounterByQE[qeId]++;

        emit TDReportAdded(tdId);

        return tdId;
    }

    function isTDValid(uint256 tdId) external view returns (bool) {
        TrustDomainStorage.Layout storage layout = TrustDomainStorage.layout();
        return layout.tdQuotes[tdId].REPORT_DATA1 != 0 && block.timestamp <= layout.tdValidityEnd[tdId];
    }

    function getTDSignerAddress(uint256 tdId) external view returns (address) {
        return TrustDomainStorage.layout().tdSignerAddress[tdId];
    }

    function getTD(uint256 tdId) external view returns (TDQuote memory) {
        return TrustDomainStorage.layout().tdQuotes[tdId];
    }

    function getQE(uint256 qeId) external view returns (QEReport memory) {
        return TrustDomainStorage.layout().qeReports[qeId];
    }

    function getQEId(uint256 tdId) external view returns (uint256 qeId) {
        return TrustDomainStorage.layout().tdToQe[tdId];
    }

    function getQEAuthority(uint256 qeId) external view returns (uint256 platformSerial, uint256 pckSerial) {
        TrustDomainStorage.QEAuthority memory authority = TrustDomainStorage.layout().qeAuthorities[qeId];
        return (authority.platformSerial, authority.pckSerial);
    }

    function revokePlatformCA(uint256 serial) external onlyOwner {
        TrustDomainStorage.Layout storage layout = TrustDomainStorage.layout();
        if (layout.pckCounterByPlatformCA[serial] > 0) {
            revert PlatformCARevocation_PCKsExist();
        }
        delete layout.platformCAs[serial];

        emit PlatformCARevoked(serial);
    }

    function revokePCK(uint256 platformSerial, uint256 pckSerial) external onlyOwner {
        TrustDomainStorage.Layout storage layout = TrustDomainStorage.layout();
        if (layout.qeCounterByProcessorPCK[platformSerial][pckSerial] > 0) {
            revert PCKRevocation_QEExist();
        }
        delete layout.processorPCKs[platformSerial][pckSerial];
        layout.pckCounterByPlatformCA[platformSerial]--;

        emit PCKRevoked(platformSerial, pckSerial);
    }

    function revokeQE(uint256 qeId) external onlyOwner {
        TrustDomainStorage.Layout storage layout = TrustDomainStorage.layout();
        if (layout.tdCounterByQE[qeId] > 0) {
            revert QERevocation_TDExist();
        }
        TrustDomainStorage.QEAuthority memory authority = layout.qeAuthorities[qeId];
        delete layout.qeReports[qeId];
        delete layout.qeAuthorities[qeId];
        layout.qeCounterByProcessorPCK[authority.platformSerial][authority.pckSerial]--;

        emit QEReportRevoked(qeId);
    }

    function revokeTD(uint256 tdId) external onlyOwner {
        TrustDomainStorage.Layout storage layout = TrustDomainStorage.layout();
        layout.tdCounterByQE[layout.tdToQe[tdId]]--;
        delete layout.tdQuotes[tdId];
        delete layout.tdSignerAddress[tdId];
        delete layout.tdToQe[tdId];

        emit TDReportRevoked(tdId);
    }

    function getPCKCounterByPlatformCA(uint256 platformSerial) external view returns (uint256) {
        return TrustDomainStorage.layout().pckCounterByPlatformCA[platformSerial];
    }
    
    function getQECounterByProcessorPCK(uint256 platformSerial, uint256 pckSerial) external view returns (uint256) {
        return TrustDomainStorage.layout().qeCounterByProcessorPCK[platformSerial][pckSerial];
    }

    function getTDCounterByQE(uint256 qeId) external view returns (uint256) {
        return TrustDomainStorage.layout().tdCounterByQE[qeId];
    }

    function _convertPublicKeyToAddress(bytes memory publicKey) private pure returns (address) {
        require(publicKey.length == 64, "Invalid public key length");
        bytes32 hash = keccak256(publicKey);
        return address(uint160(uint256(hash)));
    }

    function _calculateTDId(TDQuote memory tdQuote) private pure returns (uint256 tdId) {
        return uint256(keccak256(abi.encode(tdQuote)));
    }

    /*
     * @dev Convert a DER-encoded time to a unix timestamp
     * @param x509Time The DER-encoded time
     * @return The unix timestamp
     */
    function _fromDERToTimestamp(bytes memory x509Time) private pure returns (uint256) {
        uint16 yrs;
        uint8 mnths;
        uint8 dys;
        uint8 hrs;
        uint8 mins;
        uint8 secs;
        uint8 offset;

        if (x509Time.length == 13) {
            if (uint8(x509Time[0]) - 48 < 5) yrs += 2000;
            else yrs += 1900;
        } else {
            yrs += (uint8(x509Time[0]) - 48) * 1000 + (uint8(x509Time[1]) - 48) * 100;
            offset = 2;
        }
        yrs += (uint8(x509Time[offset + 0]) - 48) * 10 + uint8(x509Time[offset + 1]) - 48;
        mnths = (uint8(x509Time[offset + 2]) - 48) * 10 + uint8(x509Time[offset + 3]) - 48;
        dys += (uint8(x509Time[offset + 4]) - 48) * 10 + uint8(x509Time[offset + 5]) - 48;
        hrs += (uint8(x509Time[offset + 6]) - 48) * 10 + uint8(x509Time[offset + 7]) - 48;
        mins += (uint8(x509Time[offset + 8]) - 48) * 10 + uint8(x509Time[offset + 9]) - 48;
        secs += (uint8(x509Time[offset + 10]) - 48) * 10 + uint8(x509Time[offset + 11]) - 48;


        return DateTimeLib.dateTimeToTimestamp(yrs, mnths, dys, hrs, mins, secs);
    }
}
