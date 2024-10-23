// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/IV1RequestCallProxy.sol";
import "../interfaces/IV1RequestCallRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract V1RequestCallRegistry is IV1RequestCallRegistry, Ownable {
    enum RequestCallStatus {
        Created,
        Completed
    }

    struct RequestCall {
        bytes32 id;
        bytes32 requestSpecId;
        address callbackAddress;
        bytes4 callbackMethod;
        uint32 callbackGasLimit;
        RequestCallStatus status;
        uint256 price;
    }

    IV1RequestCallProxy internal requestCallProxy;

    mapping(bytes32 => RequestCall) requestCalls;

    constructor(address initialOwner, address requestCallProxyAddress) Ownable(initialOwner) {
        requestCallProxy = IV1RequestCallProxy(requestCallProxyAddress);
    }

    function sendRequest(
        bytes32 requestSpecId,
        address callbackAddress,
        bytes4 callbackMethod,
        uint32 callbackGasLimit
    ) external payable returns (bytes32 requestCallId, uint256 requestCallPrice) {
        requestCallPrice = requestCallProxy.calculateRequestCallPrice(callbackGasLimit);
        require(msg.value >= requestCallPrice, "Insufficient value sent");

        requestCallId = requestCallProxy.sendRequest(requestSpecId);

        requestCalls[requestCallId] = RequestCall(
            requestCallId,
            requestSpecId,
            callbackAddress,
            callbackMethod,
            callbackGasLimit,
            RequestCallStatus.Created,
            requestCallPrice
        );

        if (msg.value > requestCallPrice) {
            payable(msg.sender).transfer(msg.value - requestCallPrice);
        }

        return (requestCallId, requestCallPrice);
    }

    function processResponse(
        bytes32 requestCallId,
        RequestCallResult memory requestCallResult
    ) external {
        RequestCall memory requestCall = requestCalls[requestCallId];
        requestCallProxy.processResponse{value: requestCall.price}(
            requestCallId,
            requestCall.callbackAddress,
            requestCall.callbackMethod,
            requestCall.callbackGasLimit,
            requestCallResult,
            payable(msg.sender)
        );
    }

    function changeRequestCallProxy(address newContractAddress) external onlyOwner {
        requestCallProxy = IV1RequestCallProxy(newContractAddress);
    }
}
