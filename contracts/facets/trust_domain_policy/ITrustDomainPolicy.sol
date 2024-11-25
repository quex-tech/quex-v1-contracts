// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface ITrustDomainPolicy {
    function isAllowed(address tdAddress) external view returns (bool);
}

interface ITrustDomainPolicyInternal {
    function allowTD(address tdAddress) external;

    function disallowTD(address tdAddress) external;
}
