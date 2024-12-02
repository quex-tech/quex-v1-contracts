// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

struct RequestResult {
    address tdAddress;
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

interface IFeedRequestRegistry {
    event FeedRequestCreated(bytes32 requestId, bytes32 feedId);
    event FeedRequestCompleted(
        bytes32 requestId,
        address relayer,
        address callbackAddress,
        bytes4 callbackMethod,
        uint32 callbackGasLimit,
        bool callbackSuccess
    );

    function sendFeedRequest(
        bytes32 feedId,
        address callbackAddress,
        bytes4 callbackMethod,
        uint32 callbackGasLimit
    ) external payable returns (bytes32 requestId, uint256 requestPrice);
}
