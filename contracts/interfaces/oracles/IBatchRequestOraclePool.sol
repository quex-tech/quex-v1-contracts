// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./IRequestOraclePool.sol";

uint256 constant MAX_BATCH_SIZE = 8;

struct BatchRequestAction {
    HTTPRequest[] requests;
    HTTPPrivatePatch[] patches;
    string responseSchema;
    string jqFilter;
}

interface IBatchRequestOraclePool {
    error BatchSizeOutOfRange();
    error PatchCountMismatch();

    event BatchRequestActionAdded(uint256 indexed actionId);

    function addBatchAction(BatchRequestAction memory batchAction) external returns (uint256 actionId);

    function addBatchActionByParts(
        bytes32[] memory requestIds,
        bytes32[] memory patchIds,
        bytes32 schemaId,
        bytes32 filterId
    ) external returns (uint256 actionId);

    function getBatchAction(uint256 actionId) external view returns (bytes memory);

    function maxBatchSize() external pure returns (uint256);
}
