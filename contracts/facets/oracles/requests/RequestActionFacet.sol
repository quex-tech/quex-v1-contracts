// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../../interfaces/core/IFlowRegistry.sol";
import "../../../interfaces/core/IQuexActionRegistry.sol";
import "../../../interfaces/oracles/IRequestOraclePool.sol";
import "../common/quex_address/IQuexAddressRegistry.sol";
import "./RequestOracleStorage.sol";

contract RequestActionFacet is IRequestOraclePool {
    function addRequest(HTTPRequest memory request) public returns (bytes32 requestId) {
        require(bytes(request.host).length > 0, "Host is required");

        requestId = keccak256(abi.encode(request));
        RequestOracleStorage.layout().requests[requestId] = request;
        emit RequestAdded(requestId);
        return requestId;
    }

    function addPrivatePatch(HTTPPrivatePatch memory privatePatch) public returns (bytes32 patchId) {
        patchId = _isEmptyPatch(privatePatch)
            ? bytes32(0)
            : keccak256(abi.encode(privatePatch));
        if (patchId != 0) {
            require(privatePatch.tdAddress != address(0));
            RequestOracleStorage.layout().privatePatches[patchId] = privatePatch;
        }
        emit PrivatePatchAdded(patchId);
        return patchId;
    }

    function addJqFilter(string memory jqFilter) public returns (bytes32 filterId) {
        require(bytes(jqFilter).length > 0, "Filter couldn't be empty");
        filterId = keccak256(bytes(jqFilter));
        RequestOracleStorage.layout().jqFilters[filterId] = jqFilter;
        emit JqFilterAdded(filterId);
        return filterId;
    }

    function addResponseSchema(string memory responseSchema) public returns (bytes32 schemaId) {
        require(bytes(responseSchema).length > 0, "Schema couldn't be empty");
        schemaId = keccak256(bytes(responseSchema));
        RequestOracleStorage.layout().resultSchemas[schemaId] = responseSchema;
        emit ResultSchemaAdded(schemaId);
        return schemaId;
    }

    function addActionByParts(
        bytes32 requestId,
        bytes32 patchId,
        bytes32 schemaId,
        bytes32 filterId
    ) external returns (uint256 actionId) {
        RequestOracleStorage.Layout storage layout = RequestOracleStorage.layout();
        RequestOracleStorage.RequestActionInternal memory requestActionInternal = RequestOracleStorage
            .RequestActionInternal(requestId, patchId, schemaId, filterId);

        RequestAction memory requestAction = _getRequestAction(requestActionInternal);

        if (bytes(requestAction.request.host).length == 0) {
            revert RequestNotFound();
        }
        if (patchId != 0 && requestAction.patch.tdAddress == address(0)) {
            revert PrivatePatchNotFound();
        }
        if (bytes(requestAction.responseSchema).length == 0) {
            revert ResponseSchemaNotFound();
        }
        if (bytes(requestAction.jqFilter).length == 0) {
            revert JqFilterNotFound();
        }

        actionId = _calculateActionId(requestAction);
        layout.requestActions[actionId] = requestActionInternal;
        emit RequestActionAdded(actionId);
        return actionId;
    }

    function addAction(RequestAction calldata requestAction) external returns (uint256 actionId) {
        RequestOracleStorage.Layout storage layout = RequestOracleStorage.layout();

        bytes32 requestId = addRequest(requestAction.request);
        bytes32 patchId = addPrivatePatch(requestAction.patch);
        bytes32 filterId = addJqFilter(requestAction.jqFilter);
        bytes32 schemaId = addResponseSchema(requestAction.responseSchema);

        RequestOracleStorage.RequestActionInternal memory requestActionInternal = RequestOracleStorage
            .RequestActionInternal(requestId, patchId, schemaId, filterId);

        actionId = _calculateActionId(requestAction);
        layout.requestActions[actionId] = requestActionInternal;
        emit RequestActionAdded(actionId);
        return actionId;
    }

    function getAction(uint256 actionId) external view returns (bytes memory action) {
        RequestOracleStorage.RequestActionInternal memory requestActionInternal = RequestOracleStorage
            .layout()
            .requestActions[actionId];

        RequestAction memory requestAction = _getRequestAction(requestActionInternal);
        return abi.encode(requestAction);
    }

    function _getRequestAction(
        RequestOracleStorage.RequestActionInternal memory requestActionInternal
    ) private view returns (RequestAction memory requestAction) {
        RequestOracleStorage.Layout storage layout = RequestOracleStorage.layout();
        return
            RequestAction(
                layout.requests[requestActionInternal.requestId],
                layout.privatePatches[requestActionInternal.patchId],
                layout.resultSchemas[requestActionInternal.schemaId],
                layout.jqFilters[requestActionInternal.filterId]
            );
    }

    function _calculateActionId(RequestAction memory requestAction) private pure returns (uint256) {
        return uint256(keccak256(abi.encode(requestAction)));
    }

    function _isEmptyPatch(HTTPPrivatePatch memory patch) private pure returns (bool) {
        return
            patch.pathSuffix.length == 0 &&
            patch.body.length == 0 &&
            patch.headers.length == 0 &&
            patch.parameters.length == 0;
    }
}
