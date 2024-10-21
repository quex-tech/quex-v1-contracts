// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/IV1RequestSpecRegistry.sol";

contract V1RequestSpecRegistry is IV1RequestSpecRegistry {
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

    function addRequest(HTTPRequest memory request) external returns (bytes32 requestId) {
        requestId = keccak256(abi.encode(request));
        requests[requestId] = request;
        return requestId;
    }

    function addPrivatePatch(uint256 tdId, HTTPPrivatePatch memory privatePatch) external returns (bytes32 patchId) {
        patchId = keccak256(abi.encodePacked(tdId, abi.encode(privatePatch)));
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

    function addRequestSpec(
        bytes32 requestId,
        bytes32 patchId,
        bytes32 filterId,
        bytes32 schemaId
    ) external returns (bytes32 requestSpecId) {
        RequestSpecInternal memory requestSpecInternal = RequestSpecInternal(requestId, patchId, filterId, schemaId);
        requestSpecId = keccak256(abi.encode(requestSpecInternal));
        requestSpecs[requestSpecId] = requestSpecInternal;
        return requestSpecId;
    }

    function getRequestSpec(bytes32 requestSpecId) external view returns (uint256 tdId, RequestSpec memory requestSpec) {
        RequestSpecInternal memory requestSpecInternal = requestSpecs[requestSpecId];
        requestSpec = RequestSpec(
            requests[requestSpecInternal.requestId],
            privatePatches[requestSpecInternal.patchId],
            jqFilters[requestSpecInternal.filterId],
            resultSchemas[requestSpecInternal.schemaId]
        );
        return (privatePatchTdIds[requestSpecInternal.patchId], requestSpec);
    }
}
