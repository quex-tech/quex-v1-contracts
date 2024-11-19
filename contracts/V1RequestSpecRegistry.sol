// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/IV1FeedRegistryPolicy.sol";
import "../interfaces/IV1RequestSpecRegistry.sol";
import "../interfaces/IV1TrustDomainRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract V1RequestSpecRegistry is IV1RequestSpecRegistry, Ownable {
    event RequestAdded(bytes32 requestId);
    event PrivatePatchAdded(bytes32 patchId);
    event JqFilterAdded(bytes32 filterId);
    event ResultSchemaAdded(bytes32 schemaId);
    event RequestSpecAdded(bytes32 requestSpecId);

    struct RequestSpecInternal {
        bytes32 requestId;
        bytes32 patchId;
        bytes32 schemaId;
        bytes32 filterId;
    }

    mapping(bytes32 => HTTPRequest) requests;
    mapping(bytes32 => HTTPPrivatePatch) privatePatches;
    mapping(bytes32 => uint256) privatePatchTdIds;
    mapping(bytes32 => string) jqFilters;
    mapping(bytes32 => string) resultSchemas;
    mapping(bytes32 => RequestSpecInternal) requestSpecs;

    IV1TrustDomainRegistry internal trustDomainRegistry;
    IV1FeedRegistryPolicy internal feedRegistryPolicy;

    modifier onlyAllowed() {
        require(feedRegistryPolicy.isAllowed(msg.sender), "Caller is not allowed");
        _;
    }

    constructor(
        address initialOwner,
        address trustDomainRegistryAddress,
        address feedRegistryPolicyAddress
    ) Ownable(initialOwner) {
        trustDomainRegistry = IV1TrustDomainRegistry(trustDomainRegistryAddress);
        feedRegistryPolicy = IV1FeedRegistryPolicy(feedRegistryPolicyAddress);
    }

    function addRequest(HTTPRequest memory request) external onlyAllowed returns (bytes32 requestId) {
        requestId = keccak256(abi.encode(request));
        requests[requestId] = request;
        emit RequestAdded(requestId);
        return requestId;
    }

    function addPrivatePatch(uint256 tdId, HTTPPrivatePatch memory privatePatch) external onlyAllowed returns (bytes32 patchId) {
        require(trustDomainRegistry.isAllowed(tdId), "Trust Domain is not allowed to use");

        patchId = keccak256(abi.encodePacked(tdId, abi.encode(privatePatch)));
        privatePatches[patchId] = privatePatch;
        emit PrivatePatchAdded(patchId);
        return patchId;
    }

    function addJqFilter(string memory jqFilter) external onlyAllowed returns (bytes32 filterId) {
        filterId = keccak256(bytes(jqFilter));
        jqFilters[filterId] = jqFilter;
        emit JqFilterAdded(filterId);
        return filterId;
    }

    function addResponseSchema(string memory responseSchema) external onlyAllowed returns (bytes32 schemaId) {
        schemaId = keccak256(bytes(responseSchema));
        resultSchemas[schemaId] = responseSchema;
        emit ResultSchemaAdded(schemaId);
        return schemaId;
    }

    function addRequestSpec(
        bytes32 requestId,
        bytes32 patchId,
        bytes32 schemaId,
        bytes32 filterId
    ) external onlyAllowed returns (bytes32 requestSpecId) {
        require(bytes(requests[requestId].host).length != 0, "Request not found");
        require(patchId == 0 || privatePatchTdIds[patchId] != 0, "Private patch not found");
        require(bytes(resultSchemas[schemaId]).length != 0, "Result schema not found");
        require(bytes(jqFilters[filterId]).length != 0, "jq filter not found");

        RequestSpecInternal memory requestSpecInternal = RequestSpecInternal(requestId, patchId, schemaId, filterId);
        requestSpecId = keccak256(abi.encode(requestSpecInternal));
        requestSpecs[requestSpecId] = requestSpecInternal;
        emit RequestSpecAdded(requestSpecId);
        return requestSpecId;
    }

    function getRequestSpec(
        bytes32 requestSpecId
    ) external view returns (uint256 tdId, RequestSpec memory requestSpec) {
        RequestSpecInternal memory requestSpecInternal = requestSpecs[requestSpecId];
        return (privatePatchTdIds[requestSpecInternal.patchId], _getRequestSpec(requestSpecInternal));
    }

    function changeTrustDomainRegistry(address newContractAddress) external onlyOwner {
        trustDomainRegistry = IV1TrustDomainRegistry(newContractAddress);
    }

    function changeFeedRegistryPolicy(address newContractAddress) external onlyOwner {
        feedRegistryPolicy = IV1FeedRegistryPolicy(newContractAddress);
    }

    function _calculateRequestSpecId(RequestSpecInternal memory requestSpecInternal) private view returns (bytes32) {
        RequestSpec memory requestSpec = _getRequestSpec(requestSpecInternal);
        return keccak256(abi.encode(requestSpec));
    }

    function _getRequestSpec(
        RequestSpecInternal memory requestSpecInternal
    ) private view returns (RequestSpec memory requestSpec) {
        return
            RequestSpec(
                requests[requestSpecInternal.requestId],
                privatePatches[requestSpecInternal.patchId],
                resultSchemas[requestSpecInternal.schemaId],
                jqFilters[requestSpecInternal.filterId]
            );
    }
}
