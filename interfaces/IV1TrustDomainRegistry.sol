// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IV1TrustDomainRegistry {
    function getSignerAddress(uint256 tdId) external view returns (address);
    function isAllowed(uint256 tdId) external view returns (bool);
}
