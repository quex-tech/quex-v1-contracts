// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

enum RequestMethod {
    Get,
    Post,
    Put,
    Patch,
    Delete,
    Options,
    Trace
}

struct RequestHeader {
    string key;
    string value;
}

struct QueryParameter {
    string key;
    string value;
}

struct HTTPRequest {
    RequestMethod method;
    string host;
    string path;
    RequestHeader[] headers;
    QueryParameter[] parameters;
    bytes body;
}

struct RequestHeaderPatch {
    string key;
    bytes ciphertext;
}

struct QueryParameterPatch {
    string key;
    bytes ciphertext;
}

struct HTTPPrivatePatch {
    bytes pathSuffix;
    RequestHeaderPatch[] headers;
    QueryParameterPatch[] parameters;
    bytes body;
}

struct QuexRequest {
    HTTPRequest request;
    HTTPPrivatePatch patch;
    string filter;
    string schema;
}

interface IV1RequestTemplateRegistry {
    function addRequest(HTTPRequest memory request) external returns (bytes32 requestId);

    function addPrivatePatch(HTTPPrivatePatch memory privatePatch) external returns (bytes32 patchId);

    function addJqFilter(string memory jqFilter) external returns (bytes32 filterId);

    function addResponseSchema(string memory responseSchema) external returns (bytes32 schemaId);

    function addQuexRequest(
        bytes32 requestId,
        bytes32 patchId,
        bytes32 filterId,
        bytes32 schemaId
    ) external returns (bytes32 quexRequestId);

    function getRequest(bytes32 requestId) external view returns (HTTPRequest memory request);

    function getPrivatePatch(bytes32 patchId) external view returns (HTTPPrivatePatch memory privatePatch);

    function getJqFilter(bytes32 filterId) external view returns (string memory jqFilter);

    function getResponseSchema(bytes32 schemaId) external view returns (string memory responseSchema);

    function getQuexRequest(bytes32 quexRequestId) external view returns (QuexRequest memory quexRequest);
}
