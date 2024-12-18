// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./IFeedRequestRegistry.sol";

interface IFeedRequestRegistryExtended is IFeedRequestRegistry {
    function processFeedResponse(bytes32 requestId, RequestResult memory requestResult) external;
}