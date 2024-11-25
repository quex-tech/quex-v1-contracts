// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

struct RequestResult {
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
    bytes32 feedId;
    bytes value;
}

interface IRequestRegistry {
    event RequestCreated(bytes32 requestId, bytes32 feedId);
    event RequestCompleted(
        bytes32 requestId,
        address relayer,
        address callbackAddress,
        bytes4 callbackMethod,
        uint32 callbackGasLimit,
        bool callbackSuccess
    );

    function sendRequest(
        bytes32 feedId,
        address callbackAddress,
        bytes4 callbackMethod,
        uint32 callbackGasLimit
    ) external payable returns (bytes32 requestId, uint256 requestPrice);
}

interface IRequestRegistryInternal is IRequestRegistry {
    function processResponse(bytes32 requestId, RequestResult memory requestResult) external;
}
