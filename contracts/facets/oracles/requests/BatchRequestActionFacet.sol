// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../../interfaces/oracles/IBatchRequestOraclePool.sol";
import "./BatchRequestOracleStorage.sol";
import "./RequestActionFacet.sol";

contract BatchRequestActionFacet is RequestActionFacet, IBatchRequestOraclePool {
    uint256 internal constant MAX_BATCH_SIZE = 8;

    function addBatchAction(BatchRequestAction memory batchAction) external returns (uint256 actionId) {
        _validateBatchSize(batchAction.requests.length, batchAction.patches.length);
        uint256 sourceCount = batchAction.requests.length;
        bytes32[] memory requestIds = new bytes32[](sourceCount);
        bytes32[] memory patchIds = new bytes32[](sourceCount);
        for (uint256 i = 0; i < sourceCount; ++i) {
            requestIds[i] = addRequest(batchAction.requests[i]);
            patchIds[i] = addPrivatePatch(batchAction.patches[i]);
        }
        bytes32 filterId = addJqFilter(batchAction.jqFilter);
        bytes32 schemaId = addResponseSchema(batchAction.responseSchema);

        actionId = _calculateBatchActionId(batchAction);
        BatchRequestOracleStorage.layout().batchActions[actionId] = BatchRequestOracleStorage.BatchActionInternal(
            requestIds,
            patchIds,
            schemaId,
            filterId
        );
        emit BatchRequestActionAdded(actionId);
        return actionId;
    }

    function addBatchActionByParts(
        bytes32[] memory requestIds,
        bytes32[] memory patchIds,
        bytes32 schemaId,
        bytes32 filterId
    ) external returns (uint256 actionId) {
        _validateBatchSize(requestIds.length, patchIds.length);

        BatchRequestOracleStorage.BatchActionInternal memory batchActionInternal = BatchRequestOracleStorage
            .BatchActionInternal(requestIds, patchIds, schemaId, filterId);

        BatchRequestAction memory batchAction = _getBatchAction(batchActionInternal);

        for (uint256 i = 0; i < requestIds.length; ++i) {
            if (bytes(batchAction.requests[i].host).length == 0) {
                revert RequestNotFound();
            }
            if (patchIds[i] != 0 && batchAction.patches[i].tdAddress == address(0)) {
                revert PrivatePatchNotFound();
            }
        }
        if (bytes(batchAction.responseSchema).length == 0) {
            revert ResponseSchemaNotFound();
        }
        if (bytes(batchAction.jqFilter).length == 0) {
            revert JqFilterNotFound();
        }

        actionId = _calculateBatchActionId(batchAction);
        BatchRequestOracleStorage.layout().batchActions[actionId] = batchActionInternal;
        emit BatchRequestActionAdded(actionId);
        return actionId;
    }

    function getBatchAction(uint256 actionId) external view returns (bytes memory) {
        BatchRequestOracleStorage.BatchActionInternal memory batchActionInternal = BatchRequestOracleStorage
            .layout()
            .batchActions[actionId];

        return abi.encode(_getBatchAction(batchActionInternal));
    }

    function _getBatchAction(
        BatchRequestOracleStorage.BatchActionInternal memory batchActionInternal
    ) private view returns (BatchRequestAction memory batchAction) {
        RequestOracleStorage.Layout storage layout = RequestOracleStorage.layout();
        uint256 sourceCount = batchActionInternal.requestIds.length;

        HTTPRequest[] memory requests = new HTTPRequest[](sourceCount);
        HTTPPrivatePatch[] memory patches = new HTTPPrivatePatch[](sourceCount);
        for (uint256 i = 0; i < sourceCount; ++i) {
            requests[i] = layout.requests[batchActionInternal.requestIds[i]];
            patches[i] = layout.privatePatches[batchActionInternal.patchIds[i]];
        }

        return
            BatchRequestAction(
                requests,
                patches,
                layout.resultSchemas[batchActionInternal.schemaId],
                layout.jqFilters[batchActionInternal.filterId]
            );
    }

    function _calculateBatchActionId(BatchRequestAction memory batchAction) private pure returns (uint256) {
        return uint256(keccak256(abi.encode(batchAction)));
    }

    function _validateBatchSize(uint256 requestCount, uint256 patchCount) private pure {
        if (requestCount == 0 || requestCount > MAX_BATCH_SIZE) {
            revert BatchSizeOutOfRange();
        }
        if (patchCount != requestCount) {
            revert BatchLengthMismatch();
        }
    }
}
