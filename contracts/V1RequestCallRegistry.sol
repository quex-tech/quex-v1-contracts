// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/IV1RequestCallProxy.sol";
import "../interfaces/IV1RequestCallRegistry.sol";
import "../interfaces/IV1RequestTemplateRegistry.sol";
import "../interfaces/IV1TrustDomainRegistry.sol";

contract V1RequestCallRegistry is IV1RequestCallRegistry {
    enum RequestCallStatus {
        Created,
        Completed
    }

    struct RequestCall {
        bytes32 id;
        address callbackAddress;
        bytes4 callbackMethod;
        uint32 callbackGasLimit;
        RequestCallStatus status;
        uint256 price;
    }

    IV1RequestCallProxy internal immutable requestCallProxy;
    IV1TrustDomainRegistry internal immutable trustDomainRegistry;
    IV1RequestTemplateRegistry internal immutable requestTemplateRegistry;

    mapping(bytes32 => RequestCall) requestCalls;

    constructor(
        address requestCallProxyAddress,
        address requestTemplateRegistryAddress,
        address trustDomainRegistryAddress
    ) {
        requestCallProxy = IV1RequestCallProxy(requestCallProxyAddress);
        requestTemplateRegistry = IV1RequestTemplateRegistry(requestTemplateRegistryAddress);
        trustDomainRegistry = IV1TrustDomainRegistry(trustDomainRegistryAddress);
    }

    function sendRequest(
        bytes32 quexRequestId,
        address callbackAddress,
        bytes4 callbackMethod,
        uint32 callbackGasLimit
    ) external returns (bytes32 requestCallId, uint256 requestCallPrice) {
        QuexRequest memory quexRequest = requestTemplateRegistry.getQuexRequest(quexRequestId);
        require(bytes(quexRequest.request.path).length > 0, "Request template doesn't exist");

        // todo: add td isAllowed check

        requestCallPrice = requestCallProxy.calculateRequestCallPrice(callbackGasLimit);
        requestCallId = requestCallProxy.sendRequest{value: requestCallPrice}(
            quexRequestId,
            callbackAddress,
            callbackMethod,
            callbackGasLimit
        );

        requestCalls[requestCallId] = RequestCall(
            requestCallId,
            callbackAddress,
            callbackMethod,
            callbackGasLimit,
            RequestCallStatus.Created,
            requestCallPrice
        );

        return (requestCallId, requestCallPrice);
    }
}
