// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/IV1RequestCallProxy.sol";
import "../interfaces/IV1RequestCallRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract V1RequestCallRegistry is IV1RequestCallRegistry, Ownable {
    struct RequestCall {
        bytes32 feedId;
        address callbackAddress;
        bytes4 callbackMethod;
        uint32 callbackGasLimit;
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
            requestSpecId,
            callbackAddress,
            callbackMethod,
            callbackGasLimit,
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
            requestCall.feedId,
            requestCall.callbackAddress,
            requestCall.callbackMethod,
            requestCall.callbackGasLimit,
            requestCallResult,
            payable(msg.sender)
        );
        delete requestCalls[requestCallId];
    }

    function changeRequestCallProxy(address newContractAddress) external onlyOwner {
        requestCallProxy = IV1RequestCallProxy(newContractAddress);
    }
}
