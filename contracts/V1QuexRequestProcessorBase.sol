// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/IV1RequestRegistry.sol";

abstract contract V1QuexRequestProcessorBase {
    function processResponse(bytes32 requestId, DataItem memory response) external virtual;
}