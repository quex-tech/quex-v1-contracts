// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

enum IdType {
    RequestId,
    FlowId
}

struct Flow {
    uint256 gasLimit;
    uint256 actionId;
    address consumer;
    address pool;
    bytes4 callback;
}

struct DataItem {
    uint256 timestamp;
    uint256 error;
    bytes value;
}

struct OracleMessage {
    uint256 actionId;
    DataItem dataItem;
}

struct ETHSignature {
    bytes32 r;
    bytes32 s;
    uint8 v;
}