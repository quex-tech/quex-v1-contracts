// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./FeedModels.sol";

interface IFeedRegistry {
    event RequestAdded(bytes32 requestId);
    event PrivatePatchAdded(bytes32 patchId);
    event JqFilterAdded(bytes32 filterId);
    event ResultSchemaAdded(bytes32 schemaId);
    event FeedAdded(bytes32 feedId);

    function addRequest(HTTPRequest memory request) external returns (bytes32 requestId);

    function addPrivatePatch(uint256 tdId, HTTPPrivatePatch memory privatePatch) external returns (bytes32 patchId);

    function addJqFilter(string memory jqFilter) external returns (bytes32 filterId);

    function addResponseSchema(string memory responseSchema) external returns (bytes32 schemaId);

    function addFeed(
        bytes32 requestId,
        bytes32 patchId,
        bytes32 filterId,
        bytes32 schemaId
    ) external returns (bytes32 feedId);

    function getFeed(bytes32 feedId) external view returns (uint256 tdId, Feed memory feed);
}