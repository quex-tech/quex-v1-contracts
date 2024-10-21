// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/IV1RequestCallProxy.sol";

contract V1RequestCallProxy is IV1RequestCallProxy {
    uint256 private requestCallIdNonce = 0; 

    event RequestCallCreated(bytes32 requestCallId, bytes32 requestSpecId);

    function calculateRequestCallPrice(uint32 callbackGasLimit) external view returns (uint256 requestCallPrice) {
        return callbackGasLimit * tx.gasprice;
    }

    function sendRequest(bytes32 requestSpecId) external payable returns (bytes32 requestCallId) {
        requestCallId = _createRequestCallId(requestSpecId);
        emit RequestCallCreated(requestCallId, requestSpecId);
        return requestCallId;
    }

    function _createRequestCallId(bytes32 requestSpecId) private returns (bytes32 requestCallId) {
        ++requestCallIdNonce;
        return keccak256(abi.encode(requestSpecId, msg.sender, block.timestamp, block.number, requestCallIdNonce));
    }
}
