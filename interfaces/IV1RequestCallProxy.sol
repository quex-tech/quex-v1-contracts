// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/IV1RequestCallRegistry.sol";

interface IV1RequestCallProxy {
    function calculateRequestCallPrice(uint32 callbackGasLimit) external view returns (uint256 requestCallPrice);

    function sendRequest(bytes32 requestSpecId) external returns (bytes32 requestCallId);

    function processResponse(
        bytes32 requestCallId,
        address callbackAddress,
        bytes4 callbackMethod,
        uint32 callbackGasLimit,
        RequestCallResult memory requestCallResult,
        address payable relayerAddress
    ) external payable;
}
