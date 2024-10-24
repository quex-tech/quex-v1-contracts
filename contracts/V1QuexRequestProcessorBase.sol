// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/IV1RequestCallRegistry.sol";

abstract contract V1QuexRequestProcessorBase {
    function processResponse(bytes32 requestCallId, DataItem memory response) external virtual;
}