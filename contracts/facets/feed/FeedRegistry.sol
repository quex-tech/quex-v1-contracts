// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./FeedModels.sol";
import "./FeedStorage.sol";

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

contract FeedRegistry is IFeedRegistry {
    error FeedRequestNotFound();
    error FeedPrivatePatchNotFound();
    error FeedJqFilterNotFound();
    error FeedResponseSchemaNotFound();

    bytes32 public constant emptyPatchId = 0x6b2b869b804dcf429485140926f5bad3d088ce13c9b403b8d1b9b2c85bbcb13d;

    function addRequest(HTTPRequest memory request) external returns (bytes32 requestId) {
        require(bytes(request.host).length > 0, "Host is required");

        requestId = keccak256(abi.encode(request));
        FeedStorage.layout().requests[requestId] = request;
        emit RequestAdded(requestId);
        return requestId;
    }

    function addPrivatePatch(uint256 tdId, HTTPPrivatePatch memory privatePatch) external returns (bytes32 patchId) {
        patchId = keccak256(abi.encodePacked(tdId, abi.encode(privatePatch)));
        if (patchId != emptyPatchId) {
            FeedStorage.Layout storage layout = FeedStorage.layout();
            layout.privatePatches[patchId] = privatePatch;
            layout.privatePatchTdIds[patchId] = tdId;
        }
        emit PrivatePatchAdded(patchId);
        return patchId;
    }

    function addJqFilter(string memory jqFilter) external returns (bytes32 filterId) {
        require(bytes(jqFilter).length > 0, "Filter couldn't be empty");
        filterId = keccak256(bytes(jqFilter));
        FeedStorage.layout().jqFilters[filterId] = jqFilter;
        emit JqFilterAdded(filterId);
        return filterId;
    }

    function addResponseSchema(string memory responseSchema) external returns (bytes32 schemaId) {
        require(bytes(responseSchema).length > 0, "Schema couldn't be empty");
        schemaId = keccak256(bytes(responseSchema));
        FeedStorage.layout().resultSchemas[schemaId] = responseSchema;
        emit ResultSchemaAdded(schemaId);
        return schemaId;
    }

    function addFeed(
        bytes32 requestId,
        bytes32 patchId,
        bytes32 filterId,
        bytes32 schemaId
    ) external returns (bytes32 feedId) {
        FeedStorage.Layout storage layout = FeedStorage.layout();
        FeedStorage.FeedInternal memory feedInternal = FeedStorage.FeedInternal(requestId, patchId, schemaId, filterId);

        Feed memory feed = _getFeed(feedInternal);
        uint256 tdId = layout.privatePatchTdIds[patchId];

        if (bytes(feed.request.host).length == 0) {
            revert FeedRequestNotFound();
        }
        if (tdId != 0 && !_isEmptyPatch(patchId)) {
            revert FeedPrivatePatchNotFound();
        }
        if (bytes(feed.schema).length == 0) {
            revert FeedResponseSchemaNotFound();
        }
        if (bytes(feed.filter).length == 0) {
            revert FeedJqFilterNotFound();
        }

        feedId = _calculateFeedId(feed);
        layout.feeds[feedId] = feedInternal;
        emit FeedAdded(feedId);
        return feedId;
    }

    function getFeed(bytes32 feedId) external view returns (uint256 tdId, Feed memory feed) {
        FeedStorage.Layout storage layout = FeedStorage.layout();
        FeedStorage.FeedInternal memory feedInternal = layout.feeds[feedId];

        feed = _getFeed(feedInternal);
        tdId = layout.privatePatchTdIds[feedInternal.patchId];
        return (tdId, feed);
    }

    function _getFeed(FeedStorage.FeedInternal memory feedInternal) private view returns (Feed memory feed) {
        FeedStorage.Layout storage layout = FeedStorage.layout();
        return
            Feed(
                layout.requests[feedInternal.requestId],
                layout.privatePatches[feedInternal.patchId],
                layout.resultSchemas[feedInternal.schemaId],
                layout.jqFilters[feedInternal.filterId]
            );
    }

    function _calculateFeedId(Feed memory feed) private pure returns (bytes32) {
        return keccak256(abi.encode(feed));
    }

    function _isEmptyPatch(bytes32 patchId) private pure returns (bool) {
        return patchId == 0 || patchId == emptyPatchId;
    }
}
