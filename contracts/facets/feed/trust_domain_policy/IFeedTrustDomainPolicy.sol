// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IFeedTrustDomainPolicy {
    function isTDAllowedForFeed(address tdAddress) external view returns (bool);
}
