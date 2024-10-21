// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IV1TrustDomainRegistry {
    function isAllowed(uint256 td_id) external view returns (bool);
}
