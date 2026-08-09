// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../../interfaces/oracles/IBatchRequestOraclePool.sol";
import "./BatchRequestOracleStorage.sol";
import "./RequestActionFacet.sol";

contract BatchRequestActionFacet is RequestActionFacet, IBatchRequestOraclePool {
    // keccak256("quex.action.batchRequest.v1"): domain tag keeping batch action ids
    // in a namespace disjoint from single-request action ids.
    bytes32 private constant BATCH_ACTION_DOMAIN =
        0x4968257a8b21d6e257aa6b1971196271874e7a3adcf04e8a66e5d0047185e744;

    function maxBatchSize() external pure returns (uint256) {
        return MAX_BATCH_SIZE;
    }

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

        BatchRequestOracleStorage.BatchActionInternal memory internalAction = BatchRequestOracleStorage
            .BatchActionInternal(requestIds, patchIds, schemaId, filterId);
        return _storeBatchAction(internalAction, _getBatchAction(internalAction));
    }

    function addBatchActionByParts(
        bytes32[] memory requestIds,
        bytes32[] memory patchIds,
        bytes32 schemaId,
        bytes32 filterId
    ) external returns (uint256 actionId) {
        _validateBatchSize(requestIds.length, patchIds.length);

        BatchRequestOracleStorage.BatchActionInternal memory internalAction = BatchRequestOracleStorage
            .BatchActionInternal(requestIds, patchIds, schemaId, filterId);
        BatchRequestAction memory batchAction = _getBatchAction(internalAction);

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

        return _storeBatchAction(internalAction, batchAction);
    }

    function getBatchAction(uint256 actionId) external view returns (bytes memory) {
        return abi.encode(_getBatchAction(BatchRequestOracleStorage.layout().batchActions[actionId]));
    }

    // NOTE: getAction / addAction / addActionByParts are inherited from RequestActionFacet but are
    // deliberately NOT cut into the batch pool diamond, so an IOraclePool.getAction call on a batch
    // pool fails fast through the diamond fallback instead of returning a zeroed RequestAction.

    function _storeBatchAction(
        BatchRequestOracleStorage.BatchActionInternal memory internalAction,
        BatchRequestAction memory batchAction
    ) private returns (uint256 actionId) {
        // Hash the reconstructed action so the committed id matches what getBatchAction serves,
        // even when a content-empty patch drops its tdAddress during registration.
        actionId = _calculateBatchActionId(batchAction);
        BatchRequestOracleStorage.layout().batchActions[actionId] = internalAction;
        emit BatchRequestActionAdded(actionId);
        return actionId;
    }

    function _getBatchAction(
        BatchRequestOracleStorage.BatchActionInternal memory internalAction
    ) private view returns (BatchRequestAction memory batchAction) {
        RequestOracleStorage.Layout storage layout = RequestOracleStorage.layout();
        uint256 sourceCount = internalAction.requestIds.length;

        HTTPRequest[] memory requests = new HTTPRequest[](sourceCount);
        HTTPPrivatePatch[] memory patches = new HTTPPrivatePatch[](sourceCount);
        for (uint256 i = 0; i < sourceCount; ++i) {
            requests[i] = layout.requests[internalAction.requestIds[i]];
            patches[i] = layout.privatePatches[internalAction.patchIds[i]];
        }

        return
            BatchRequestAction(
                requests,
                patches,
                layout.resultSchemas[internalAction.schemaId],
                layout.jqFilters[internalAction.filterId]
            );
    }

    function _calculateBatchActionId(BatchRequestAction memory batchAction) private pure returns (uint256) {
        return uint256(keccak256(abi.encode(BATCH_ACTION_DOMAIN, batchAction)));
    }

    function _validateBatchSize(uint256 requestCount, uint256 patchCount) private pure {
        if (requestCount == 0 || requestCount > MAX_BATCH_SIZE) {
            revert BatchSizeOutOfRange();
        }
        if (patchCount != requestCount) {
            revert PatchCountMismatch();
        }
    }
}
