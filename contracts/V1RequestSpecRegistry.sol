// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

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
        bytes32 filterId;
        bytes32 schemaId;
    }

    mapping(bytes32 => HTTPRequest) requests;
    mapping(bytes32 => HTTPPrivatePatch) privatePatches;
    mapping(bytes32 => uint256) privatePatchTdIds;
    mapping(bytes32 => string) jqFilters;
    mapping(bytes32 => string) resultSchemas;
    mapping(bytes32 => RequestSpecInternal) requestSpecs;

    IV1TrustDomainRegistry internal trustDomainRegistry;

    constructor(address initialOwner, address trustDomainRegistryAddress) Ownable(initialOwner) {
        trustDomainRegistry = IV1TrustDomainRegistry(trustDomainRegistryAddress);
    }

    function addRequest(HTTPRequest memory request) external returns (bytes32 requestId) {
        requestId = keccak256(abi.encode(request));
        requests[requestId] = request;
        emit RequestAdded(requestId);
        return requestId;
    }

    function addPrivatePatch(uint256 tdId, HTTPPrivatePatch memory privatePatch) external returns (bytes32 patchId) {
        require(trustDomainRegistry.isAllowed(tdId), "Trust Domain is not allowed to use");

        patchId = keccak256(abi.encodePacked(tdId, abi.encode(privatePatch)));
        privatePatches[patchId] = privatePatch;
        emit PrivatePatchAdded(patchId);
        return patchId;
    }

    function addJqFilter(string memory jqFilter) external returns (bytes32 filterId) {
        filterId = keccak256(bytes(jqFilter));
        jqFilters[filterId] = jqFilter;
        emit JqFilterAdded(filterId);
        return filterId;
    }

    function addResponseSchema(string memory responseSchema) external returns (bytes32 schemaId) {
        schemaId = keccak256(bytes(responseSchema));
        resultSchemas[schemaId] = responseSchema;
        emit ResultSchemaAdded(schemaId);
        return schemaId;
    }

    function addRequestSpec(
        bytes32 requestId,
        bytes32 patchId,
        bytes32 filterId,
        bytes32 schemaId
    ) external returns (bytes32 requestSpecId) {
        require(bytes(requests[requestId].host).length != 0, "Request not found");
        require(patchId == 0 || privatePatchTdIds[patchId] != 0, "Private patch not found");
        require(bytes(jqFilters[filterId]).length != 0, "jq filter not found");
        require(bytes(resultSchemas[schemaId]).length != 0, "Result schema not found");

        RequestSpecInternal memory requestSpecInternal = RequestSpecInternal(requestId, patchId, filterId, schemaId);
        requestSpecId = keccak256(abi.encode(requestSpecInternal));
        requestSpecs[requestSpecId] = requestSpecInternal;
        emit RequestSpecAdded(requestSpecId);
        return requestSpecId;
    }

    function getRequestSpec(
        bytes32 requestSpecId
    ) external view returns (uint256 tdId, RequestSpec memory requestSpec) {
        RequestSpecInternal memory requestSpecInternal = requestSpecs[requestSpecId];
        requestSpec = RequestSpec(
            requests[requestSpecInternal.requestId],
            privatePatches[requestSpecInternal.patchId],
            jqFilters[requestSpecInternal.filterId],
            resultSchemas[requestSpecInternal.schemaId]
        );
        return (privatePatchTdIds[requestSpecInternal.patchId], requestSpec);
    }

    function changeTrustDomainRegistry(address newContractAddress) external onlyOwner {
        trustDomainRegistry = IV1TrustDomainRegistry(newContractAddress);
    }
}
