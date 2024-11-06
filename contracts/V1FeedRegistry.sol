// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/IV1FeedRegistryPolicy.sol";
import "../interfaces/IV1FeedRegistry.sol";
import "../interfaces/IV1TrustDomainRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract V1FeedRegistry is IV1FeedRegistry, Ownable {
    event RequestAdded(bytes32 requestId);
    event PrivatePatchAdded(bytes32 patchId);
    event JqFilterAdded(bytes32 filterId);
    event ResultSchemaAdded(bytes32 schemaId);
    event FeedAdded(bytes32 feedId);

    struct FeedInternal {
        bytes32 requestId;
        bytes32 patchId;
        bytes32 schemaId;
        bytes32 filterId;
    }

    mapping(bytes32 => HTTPRequest) public requests;
    mapping(bytes32 => HTTPPrivatePatch) public privatePatches;
    mapping(bytes32 => uint256) public privatePatchTdIds;
    mapping(bytes32 => string) public jqFilters;
    mapping(bytes32 => string) public resultSchemas;
    mapping(bytes32 => FeedInternal) public feeds;

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

    function addFeed(
        bytes32 requestId,
        bytes32 patchId,
        bytes32 schemaId,
        bytes32 filterId
    ) external onlyAllowed returns (bytes32 feedId) {
        require(bytes(requests[requestId].host).length != 0, "Request not found");
        require(patchId == 0 || privatePatchTdIds[patchId] != 0, "Private patch not found");
        require(bytes(resultSchemas[schemaId]).length != 0, "Result schema not found");
        require(bytes(jqFilters[filterId]).length != 0, "jq filter not found");

        FeedInternal memory feedInternal = FeedInternal(requestId, patchId, schemaId, filterId);
        feedId = _calculateFeedId(feedInternal);
        feeds[feedId] = feedInternal;
        emit FeedAdded(feedId);
        return feedId;
    }

    function getFeed(
        bytes32 feedId
    ) external view returns (uint256 tdId, Feed memory feed) {
        FeedInternal memory feedInternal = feeds[feedId];
        return (privatePatchTdIds[feedInternal.patchId], _getFeed(feedInternal));
    }

    function changeTrustDomainRegistry(address newContractAddress) external onlyOwner {
        trustDomainRegistry = IV1TrustDomainRegistry(newContractAddress);
    }

    function changeFeedRegistryPolicy(address newContractAddress) external onlyOwner {
        feedRegistryPolicy = IV1FeedRegistryPolicy(newContractAddress);
    }

    function _calculateFeedId(FeedInternal memory feedId) private view returns (bytes32) {
        Feed memory feed = _getFeed(feedId);
        return keccak256(abi.encode(feed));
    }

    function _getFeed(
        FeedInternal memory feedInternal
    ) private view returns (Feed memory feed) {
        return
            Feed(
                requests[feedInternal.requestId],
                privatePatches[feedInternal.patchId],
                resultSchemas[feedInternal.schemaId],
                jqFilters[feedInternal.filterId]
            );
    }
}
