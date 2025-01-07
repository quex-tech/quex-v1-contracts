// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../../interfaces/core/IFlowRegistry.sol";
import "../../../interfaces/core/IQuexActionRegistry.sol";
import "../../../interfaces/oracles/IFeedRegistry.sol";
import "./FeedOracleStorage.sol";
import "@solidstate/contracts/access/ownable/Ownable.sol";

contract FeedActionFacet is IFeedRegistry, Ownable {
    error FeedRequestNotFound();
    error FeedPrivatePatchNotFound();
    error FeedJqFilterNotFound();
    error FeedResponseSchemaNotFound();

    function addRequest(HTTPRequest memory request) external returns (bytes32 requestId) {
        require(bytes(request.host).length > 0, "Host is required");

        requestId = keccak256(abi.encode(request));
        FeedOracleStorage.layout().requests[requestId] = request;
        emit RequestAdded(requestId);
        return requestId;
    }

    function addPrivatePatch(address tdAddress, HTTPPrivatePatch memory privatePatch) external returns (bytes32 patchId) {
        patchId = _isEmptyPatch(privatePatch)
            ? bytes32(0)
            : keccak256(abi.encodePacked(tdAddress, abi.encode(privatePatch)));
        if (patchId != 0) {
            FeedOracleStorage.Layout storage layout = FeedOracleStorage.layout();
            layout.privatePatches[patchId] = privatePatch;
            layout.privatePatchTdAddresses[patchId] = tdAddress;
        }
        emit PrivatePatchAdded(patchId);
        return patchId;
    }

    function addJqFilter(string memory jqFilter) external returns (bytes32 filterId) {
        require(bytes(jqFilter).length > 0, "Filter couldn't be empty");
        filterId = keccak256(bytes(jqFilter));
        FeedOracleStorage.layout().jqFilters[filterId] = jqFilter;
        emit JqFilterAdded(filterId);
        return filterId;
    }

    function addResponseSchema(string memory responseSchema) external returns (bytes32 schemaId) {
        require(bytes(responseSchema).length > 0, "Schema couldn't be empty");
        schemaId = keccak256(bytes(responseSchema));
        FeedOracleStorage.layout().resultSchemas[schemaId] = responseSchema;
        emit ResultSchemaAdded(schemaId);
        return schemaId;
    }

    function addFlow(
        bytes32 requestId,
        bytes32 patchId,
        bytes32 schemaId,
        bytes32 filterId,
        address consumer,
        bytes4 callback,
        uint256 gasLimit
    ) external returns (uint256 flowId) {
        FeedOracleStorage.Layout storage layout = FeedOracleStorage.layout();
        FeedOracleStorage.FeedInternal memory feedInternal = FeedOracleStorage.FeedInternal(requestId, patchId, schemaId, filterId);

        Feed memory feed = _getFeed(feedInternal);
        address tdAddress = layout.privatePatchTdAddresses[patchId];

        if (bytes(feed.request.host).length == 0) {
            revert FeedRequestNotFound();
        }
        if (patchId != 0 && tdAddress == address(0)) {
            revert FeedPrivatePatchNotFound();
        }
        if (bytes(feed.schema).length == 0) {
            revert FeedResponseSchemaNotFound();
        }
        if (bytes(feed.filter).length == 0) {
            revert FeedJqFilterNotFound();
        }

        uint256 feedId = _calculateFeedId(feed);
        layout.feeds[feedId] = feedInternal;
        emit FeedAdded(feedId);

        Flow memory flow = Flow(gasLimit, feedId, consumer, address(this), callback);
        return IFlowRegistry(getQuexAddress()).createFlow(flow);
    }

    function getAction(uint256 actionId) external view returns (address tdAddress, bytes memory action) {
        FeedOracleStorage.Layout storage layout = FeedOracleStorage.layout();
        FeedOracleStorage.FeedInternal memory feedInternal = layout.feeds[actionId];

        Feed memory feed = _getFeed(feedInternal);
        tdAddress = layout.privatePatchTdAddresses[feedInternal.patchId];
        return (tdAddress, abi.encode(feed));
    }

    function createRequest(uint256 flowId) external returns (uint256 requestId) {
        return IQuexActionRegistry(getQuexAddress()).createRequest(flowId);
    }

    // todo: extract to common facet
    function setQuexAddress(address quexAddress) external onlyOwner {
        FeedOracleStorage.layout().quexAddress = quexAddress;
    }

    // todo: extract to common facet
    function getQuexAddress() internal view returns (address) {
        return FeedOracleStorage.layout().quexAddress;
    }

    function _getFeed(FeedOracleStorage.FeedInternal memory feedInternal) private view returns (Feed memory feed) {
        FeedOracleStorage.Layout storage layout = FeedOracleStorage.layout();
        return Feed(
            layout.requests[feedInternal.requestId],
            layout.privatePatches[feedInternal.patchId],
            layout.resultSchemas[feedInternal.schemaId],
            layout.jqFilters[feedInternal.filterId]
        );
    }

    function _calculateFeedId(Feed memory feed) private pure returns (uint256) {
        return uint256(keccak256(abi.encode(feed)));
    }

    function _isEmptyPatch(HTTPPrivatePatch memory patch) private pure returns (bool) {
        return patch.pathSuffix.length == 0
            && patch.body.length == 0
            && patch.headers.length == 0
            && patch.parameters.length == 0;
    }
}
