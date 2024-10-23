// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/IV1RequestCallProxy.sol";
import "../interfaces/IV1RequestCallRegistry.sol";
import "../interfaces/IV1RequestSpecRegistry.sol";
import "../interfaces/IV1TrustDomainRegistry.sol";

contract V1RequestCallRegistry is IV1RequestCallRegistry {
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

    IV1RequestCallProxy internal immutable requestCallProxy;
    IV1TrustDomainRegistry internal immutable trustDomainRegistry;
    IV1RequestSpecRegistry internal immutable requestSpecRegistry;

    mapping(bytes32 => RequestCall) requestCalls;

    constructor(
        address requestCallProxyAddress,
        address requestSpecRegistryAddress,
        address trustDomainRegistryAddress
    ) {
        requestCallProxy = IV1RequestCallProxy(requestCallProxyAddress);
        requestSpecRegistry = IV1RequestSpecRegistry(requestSpecRegistryAddress);
        trustDomainRegistry = IV1TrustDomainRegistry(trustDomainRegistryAddress);
    }

    function sendRequest(
        bytes32 requestSpecId,
        address callbackAddress,
        bytes4 callbackMethod,
        uint32 callbackGasLimit
    ) external payable returns (bytes32 requestCallId, uint256 requestCallPrice) {
        (uint256 tdId, RequestSpec memory requestSpec) = requestSpecRegistry.getRequestSpec(requestSpecId);

        require(bytes(requestSpec.request.path).length > 0, "Request template doesn't exist");
        require(tdId == 0 || trustDomainRegistry.isAllowed(tdId), "Trust Domain is not allowed to use");

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
}
