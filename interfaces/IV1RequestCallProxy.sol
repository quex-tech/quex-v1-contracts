// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IV1RequestCallProxy {
    function calculateRequestCallPrice(uint32 callbackGasLimit) external view returns (uint256 requestCallPrice);

    function sendRequest(bytes32 requestSpecId) external payable returns (bytes32 requestCallId);
}
