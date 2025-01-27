// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../../interfaces/core/IFlowRegistry.sol";
import "../../../interfaces/core/IQuexActionRegistry.sol";
import "../../../interfaces/oracles/IRequestOraclePool.sol";
import "../common/quex_address/IQuexAddressRegistry.sol";
import "./RequestOracleStorage.sol";

contract RequestActionFacet is IRequestOraclePool {
    struct RequestAction {
        HTTPRequest request;
        HTTPPrivatePatch patch;
        string schema;
        string filter;
    }

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
        RequestOracleStorage.RequestActionInternal memory requestActionInternal = RequestOracleStorage.RequestActionInternal(requestId, patchId, schemaId, filterId);

        RequestAction memory requestAction = _getRequestAction(requestActionInternal);
        address tdAddress = layout.privatePatchTdAddresses[patchId];

        if (bytes(requestAction.request.host).length == 0) {
            revert RequestNotFound();
        }
        if (patchId != 0 && tdAddress == address(0)) {
            revert PrivatePatchNotFound();
        }
        if (bytes(requestAction.schema).length == 0) {
            revert ResponseSchemaNotFound();
        }
        if (bytes(requestAction.filter).length == 0) {
            revert JqFilterNotFound();
        }

        uint256 actionId = _calculateActionId(requestAction);
        layout.requestActions[actionId] = requestActionInternal;
        emit RequestActionAdded(actionId);

        Flow memory flow = Flow(gasLimit, actionId, address(this), consumer, callback);
        return IFlowRegistry(IQuexAddressRegistry(address(this)).getQuexAddress()).createFlow(flow);
    }

    function getAction(uint256 actionId) external view returns (bytes memory action) {
        RequestOracleStorage.RequestActionInternal memory requestActionInternal = RequestOracleStorage.layout().requestActions[actionId];

        RequestAction memory requestAction = _getRequestAction(requestActionInternal);
        return abi.encode(requestAction);
    }

    function getActionTD(uint256 actionId) external view returns (address tdAddress) {
        RequestOracleStorage.Layout storage layout = RequestOracleStorage.layout();
        RequestOracleStorage.RequestActionInternal memory requestActionInternal = layout.requestActions[actionId];

        return layout.privatePatchTdAddresses[requestActionInternal.patchId];
    }

    function startRequest(uint256 flowId) external returns (uint256 requestRunId) {
        return IQuexActionRegistry(IQuexAddressRegistry(address(this)).getQuexAddress()).createRequest(flowId);
    }

    function _getRequestAction(RequestOracleStorage.RequestActionInternal memory requestActionInternal) private view returns (RequestAction memory requestAction) {
        RequestOracleStorage.Layout storage layout = RequestOracleStorage.layout();
        return RequestAction(
            layout.requests[requestActionInternal.requestId],
            layout.privatePatches[requestActionInternal.patchId],
            layout.resultSchemas[requestActionInternal.schemaId],
            layout.jqFilters[requestActionInternal.filterId]
        );
    }

    function _calculateActionId(RequestAction memory requestAction) private pure returns (uint256) {
        return uint256(keccak256(abi.encode(requestAction.request, requestAction.patch, requestAction.schema, requestAction.filter)));
    }

    function _isEmptyPatch(HTTPPrivatePatch memory patch) private pure returns (bool) {
        return patch.pathSuffix.length == 0
            && patch.body.length == 0
            && patch.headers.length == 0
            && patch.parameters.length == 0;
    }
}
