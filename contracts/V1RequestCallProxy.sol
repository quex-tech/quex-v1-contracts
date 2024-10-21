// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/IV1RequestCallProxy.sol";

contract V1RequestCallProxy is IV1RequestCallProxy {
    uint256 private requestCallIdNonce = 0; 

    event RequestCallCreated(bytes32 requestCallId, bytes32 quexRequestId);

    function calculateRequestCallPrice(uint32 callbackGasLimit) external view returns (uint256 requestCallPrice) {
        return callbackGasLimit * tx.gasprice;
    }

    function sendRequest(bytes32 quexRequestId) external payable returns (bytes32 requestCallId) {
        requestCallId = _createRequestCallId(quexRequestId);
        emit RequestCallCreated(requestCallId, quexRequestId);
        return requestCallId;
    }

    function _createRequestCallId(bytes32 quexRequestId) private returns (bytes32 requestCallId) {
        ++requestCallIdNonce;
        return keccak256(abi.encode(quexRequestId, msg.sender, block.timestamp, block.number, requestCallIdNonce));
    }
}
