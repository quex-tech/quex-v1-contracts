// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/IV1RequestTemplateRegistry.sol";

contract V1RequestTemplateRegistry is IV1RequestTemplateRegistry {
    struct QuexRequestInternal {
        bytes32 requestId;
        bytes32 patchId;
        bytes32 filterId;
        bytes32 schemaId;
    }

    mapping(bytes32 => HTTPRequest) requests;
    mapping(bytes32 => HTTPPrivatePatch) privatePatches;
    mapping(bytes32 => string) jqFilters;
    mapping(bytes32 => string) resultSchemas;
    mapping(bytes32 => QuexRequestInternal) quexRequests;

    function addRequest(HTTPRequest memory request) external returns (bytes32 requestId) {
        requestId = keccak256(abi.encode(request));
        requests[requestId] = request;
        return requestId;
    }

    function addPrivatePatch(HTTPPrivatePatch memory privatePatch) external returns (bytes32 patchId) {
        patchId = keccak256(abi.encode(privatePatch));
        privatePatches[patchId] = privatePatch;
        return patchId;
    }

    function addJqFilter(string memory jqFilter) external returns (bytes32 filterId) {
        filterId = keccak256(bytes(jqFilter));
        jqFilters[filterId] = jqFilter;
        return filterId;
    }

    function addResponseSchema(string memory responseSchema) external returns (bytes32 schemaId) {
        schemaId = keccak256(bytes(responseSchema));
        resultSchemas[schemaId] = responseSchema;
        return schemaId;
    }

    function addQuexRequest(
        bytes32 requestId,
        bytes32 patchId,
        bytes32 filterId,
        bytes32 schemaId
    ) external returns (bytes32 quexRequestId) {
        QuexRequestInternal memory quexRequest = QuexRequestInternal(requestId, patchId, filterId, schemaId);
        quexRequestId = keccak256(abi.encode(quexRequest));
        quexRequests[quexRequestId] = QuexRequestInternal(requestId, patchId, filterId, schemaId);
        return quexRequestId;
    }

    function getRequest(bytes32 requestId) external view returns (HTTPRequest memory request) {
        return requests[requestId];
    }

    function getPrivatePatch(bytes32 patchId) external view returns (HTTPPrivatePatch memory privatePatch) {
        return privatePatches[patchId];
    }

    function getJqFilter(bytes32 filterId) external view returns (string memory jqFilter) {
        return jqFilters[filterId];
    }

    function getResponseSchema(bytes32 schemaId) external view returns (string memory responseSchema) {
        return resultSchemas[schemaId];
    }

    function getQuexRequest(bytes32 quexRequestId) external view returns (QuexRequest memory quexRequest) {
        QuexRequestInternal memory quexRequestInernal = quexRequests[quexRequestId];
        return QuexRequest(
            requests[quexRequestInernal.requestId],
            privatePatches[quexRequestInernal.patchId],
            jqFilters[quexRequestInernal.filterId],
            resultSchemas[quexRequestInernal.schemaId]
        );
    }
}
