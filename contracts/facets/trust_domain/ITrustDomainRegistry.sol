// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./TrustDomainStorage.sol";

interface ITrustDomainRegistry {
    function addPlatformCAKey(
        uint256 x,
        uint256 y,
        uint256 serial,
        bytes memory notBefore,
        bytes memory extensions,
        uint256 r,
        uint256 s
    ) external;

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
    ) external;

    function getPCK(uint256 platformSerial, uint256 pckSerial) external view returns (TrustDomainStorage.ECKey memory);

    function revokePCK(uint256 platformSerial, uint256 pckSerial) external;

    function revokePlatformCA(uint256 serial) external;

    function addQE(
        TrustDomainStorage.QEReport memory qeReport,
        uint256 platformSerial,
        uint256 pckSerial,
        uint256 r,
        uint256 s
    ) external returns (uint256 qeId);

    function addTD(
        TrustDomainStorage.TDQuote memory tdQuote,
        uint qeId,
        uint256 x,
        uint256 y,
        bytes32 authentication_data,
        uint256 r,
        uint256 s
    ) external returns (uint256 tdId);

    function getTD(uint256 tdId) external view returns (TrustDomainStorage.TDQuote memory);

    function getQE(uint256 qeId) external view returns (TrustDomainStorage.QEReport memory);

    function getQEId(uint256 tdId) external view returns (uint256 qeId);

    function getQEAuthority(uint256 qeId) external view returns (uint256 platformSerial, uint256 pckSerial);

    function getSignerAddress(uint256 tdId) external view returns (address) ;
}
