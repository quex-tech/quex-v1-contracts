// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../../interfaces/core/IFlowRegistry.sol";
import "../../../interfaces/core/IQuexActionRegistry.sol";
import "../../../interfaces/oracles/IRequestOraclePool.sol";
import "../common/quex_address/IQuexAddressRegistry.sol";
import "./RequestOracleStorage.sol";

contract RequestActionFacet is IRequestOraclePool {
    error FeedRequestNotFound();
    error FeedPrivatePatchNotFound();
    error FeedJqFilterNotFound();
    error FeedResponseSchemaNotFound();

    function addRequest(HTTPRequest memory request) external returns (bytes32 requestId) {
        require(bytes(request.host).length > 0, "Host is required");

        requestId = keccak256(abi.encode(request));
        RequestOracleStorage.layout().requests[requestId] = request;
        emit RequestAdded(requestId);
        return requestId;
    }

    function addPrivatePatch(address tdAddress, HTTPPrivatePatch memory privatePatch) external returns (bytes32 patchId) {
        patchId = _isEmptyPatch(privatePatch)
            ? bytes32(0)
            : keccak256(abi.encodePacked(tdAddress, abi.encode(privatePatch)));
        if (patchId != 0) {
            require(tdAddress != address(0));
            RequestOracleStorage.Layout storage layout = RequestOracleStorage.layout();
            layout.privatePatches[patchId] = privatePatch;
            layout.privatePatchTdAddresses[patchId] = tdAddress;
        }
        emit PrivatePatchAdded(patchId);
        return patchId;
    }

    function addJqFilter(string memory jqFilter) external returns (bytes32 filterId) {
        require(bytes(jqFilter).length > 0, "Filter couldn't be empty");
        filterId = keccak256(bytes(jqFilter));
        RequestOracleStorage.layout().jqFilters[filterId] = jqFilter;
        emit JqFilterAdded(filterId);
        return filterId;
    }

    function addResponseSchema(string memory responseSchema) external returns (bytes32 schemaId) {
        require(bytes(responseSchema).length > 0, "Schema couldn't be empty");
        schemaId = keccak256(bytes(responseSchema));
        RequestOracleStorage.layout().resultSchemas[schemaId] = responseSchema;
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
        RequestOracleStorage.Layout storage layout = RequestOracleStorage.layout();
        RequestOracleStorage.FeedInternal memory feedInternal = RequestOracleStorage.FeedInternal(requestId, patchId, schemaId, filterId);

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

        Flow memory flow = Flow(gasLimit, feedId, address(this), consumer, callback);
        return IFlowRegistry(IQuexAddressRegistry(address(this)).getQuexAddress()).createFlow(flow);
    }

    function getAction(uint256 actionId) external view returns (bytes memory action) {
        RequestOracleStorage.FeedInternal memory feedInternal = RequestOracleStorage.layout().feeds[actionId];

        Feed memory feed = _getFeed(feedInternal);
        return abi.encode(feed);
    }

    function getActionTD(uint256 actionId) external view returns (address tdAddress) {
        RequestOracleStorage.Layout storage layout = RequestOracleStorage.layout();
        RequestOracleStorage.FeedInternal memory feedInternal = layout.feeds[actionId];

        return layout.privatePatchTdAddresses[feedInternal.patchId];
    }

    function createRequest(uint256 flowId) external returns (uint256 requestId) {
        return IQuexActionRegistry(IQuexAddressRegistry(address(this)).getQuexAddress()).createRequest(flowId);
    }

    function _getFeed(RequestOracleStorage.FeedInternal memory feedInternal) private view returns (Feed memory feed) {
        RequestOracleStorage.Layout storage layout = RequestOracleStorage.layout();
        return Feed(
            layout.requests[feedInternal.requestId],
            layout.privatePatches[feedInternal.patchId],
            layout.resultSchemas[feedInternal.schemaId],
            layout.jqFilters[feedInternal.filterId]
        );
    }

    function _calculateFeedId(Feed memory feed) private pure returns (uint256) {
        return uint256(keccak256(abi.encode(feed.request, feed.patch, feed.schema, feed.filter)));
    }

    function _isEmptyPatch(HTTPPrivatePatch memory patch) private pure returns (bool) {
        return patch.pathSuffix.length == 0
            && patch.body.length == 0
            && patch.headers.length == 0
            && patch.parameters.length == 0;
    }
}
