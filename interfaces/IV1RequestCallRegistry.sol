// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IV1RequestCallRegistry {
    function sendRequest(
        bytes32 requestSpecId,
        address callbackAddress,
        bytes4 callbackMethod,
        uint32 callbackGasLimit
    ) external payable returns (bytes32 requestCallId, uint256 requestCallPrice);
}
