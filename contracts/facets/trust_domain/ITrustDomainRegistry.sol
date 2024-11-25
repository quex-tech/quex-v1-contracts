// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./TrustDomainModels.sol";

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

    function addQE(
        QEReport memory qeReport,
        uint256 platformSerial,
        uint256 pckSerial,
        uint256 r,
        uint256 s
    ) external returns (uint256 qeId);

    function addTD(
        TDQuote memory tdQuote,
        uint qeId,
        uint256 x,
        uint256 y,
        bytes32 authentication_data,
        uint256 r,
        uint256 s
    ) external returns (uint256 tdId);

    function getPCK(uint256 platformSerial, uint256 pckSerial) external view returns (ECKey memory);

    function getTD(uint256 tdId) external view returns (TDQuote memory);

    function getQE(uint256 qeId) external view returns (QEReport memory);

    function getQEId(uint256 tdId) external view returns (uint256 qeId);

    function getQEAuthority(uint256 qeId) external view returns (uint256 platformSerial, uint256 pckSerial);
}

interface ITrustDomainRegistryInternal is ITrustDomainRegistry {
    function revokePCK(uint256 platformSerial, uint256 pckSerial) external;

    function revokePlatformCA(uint256 serial) external;

    function getSignerAddress(uint256 tdId) external view returns (address);
}
