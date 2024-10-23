// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

struct RequestCallResult {
    uint256 tdId;
    DataItem dataItem;
    ETHSignature signature;
}

struct ETHSignature {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

struct DataItem {
    uint256 timestamp;
    bytes32 feedID;
    bytes value;
}

interface IV1RequestCallRegistry {
    function sendRequest(
        bytes32 requestSpecId,
        address callbackAddress,
        bytes4 callbackMethod,
        uint32 callbackGasLimit
    ) external payable returns (bytes32 requestCallId, uint256 requestCallPrice);

    function processResponse(
        bytes32 requestCallId,
        RequestCallResult memory requestCallResult
    ) external;
}
