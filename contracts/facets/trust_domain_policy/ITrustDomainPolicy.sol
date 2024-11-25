// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface ITrustDomainPolicy {
    function isAllowed(uint256 tdId) external view returns (bool);
}

interface ITrustDomainPolicyInternal {
    function allowTD(uint256 tdId) external;

    function disallowTD(uint256 tdId) external;
}
