// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/IV1RequestLogic.sol";
import "../interfaces/IV1FeedRegistry.sol";
import "../interfaces/IV1TrustDomainRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract V1RequestLogic is IV1RequestLogic, Ownable {
    uint256 private requestIdNonce = 0;
    uint256 constant private MAX_LAG = 30 minutes;

    mapping(address => bool) private allowedAddresses;

    IV1TrustDomainRegistry internal trustDomainRegistry;
    IV1FeedRegistry internal feedRegistry;

    event RequestCreated(bytes32 requestId, bytes32 feedId);
    event RequestCompleted(
        bytes32 requestId,
        address relayer,
        address callbackAddress,
        bytes4 callbackMethod,
        uint32 callbackGasLimit,
        bool callbackSuccess
    );

    modifier onlyAllowed() {
        require(allowedAddresses[msg.sender], "Caller is not allowed");
        _;
    }

    constructor(
        address initialOwner,
        address feedRegistryAddress,
        address trustDomainRegistryAddress
    ) Ownable(initialOwner) {
        feedRegistry = IV1FeedRegistry(feedRegistryAddress);
        trustDomainRegistry = IV1TrustDomainRegistry(trustDomainRegistryAddress);
    }

    function calculateRequestPrice(uint32 callbackGasLimit) external view returns (uint256 requestPrice) {
        return callbackGasLimit * tx.gasprice;
    }

    function sendRequest(bytes32 feedId) external onlyAllowed returns (bytes32 requestId) {
        (uint256 tdId, Feed memory feed) = feedRegistry.getFeed(feedId);

        require(bytes(feed.request.path).length > 0, "Request template doesn't exist");
        require(tdId == 0 || trustDomainRegistry.isAllowed(tdId), "Trust Domain is not allowed to use");

        requestId = _createRequestId(feedId);
        emit RequestCreated(requestId, feedId);

        return requestId;
    }

    function processResponse(
        bytes32 requestId,
        bytes32 feedId,
        address callbackAddress,
        bytes4 callbackMethod,
        uint32 callbackGasLimit,
        RequestResult memory requestResult,
        address payable relayerAddress
    ) external payable onlyAllowed {
        require(trustDomainRegistry.isAllowed(requestResult.tdId), "Trust Domain is not allowed to use");
        require(requestResult.dataItem.feedId == feedId, "Response feed id is different from request feed id");
        require(_isTimestampValid(requestResult.dataItem.timestamp), "Time skew is too high");
        require(_isResultSignatureValid(requestResult), "Signature is not valid");

        bytes memory payload = abi.encodeWithSelector(callbackMethod, requestId, requestResult.dataItem);
        (bool success, ) = callbackAddress.call{gas: callbackGasLimit}(payload);

        relayerAddress.transfer(msg.value);
        emit RequestCompleted(
            requestId,
            relayerAddress,
            callbackAddress,
            callbackMethod,
            callbackGasLimit,
            success
        );
    }

    function _createRequestId(bytes32 feedId) private returns (bytes32 requestId) {
        ++requestIdNonce;
        return keccak256(abi.encode(feedId, msg.sender, block.timestamp, block.number, requestIdNonce));
    }

    function _isResultSignatureValid(RequestResult memory requestResult) private view returns (bool) {
        DataItem memory data = requestResult.dataItem;
        bytes memory message = abi.encode(data.timestamp, data.feedId, data.value);
        address signer = trustDomainRegistry.getSignerAddress(requestResult.tdId);
        ETHSignature memory signature = requestResult.signature;
        bytes32 messageHash = keccak256(message);
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        return ecrecover(ethSignedMessageHash, signature.v, signature.r, signature.s) == signer;
    }

    function _isTimestampValid(uint256 timestamp) private view returns (bool) {
        return (block.timestamp - MAX_LAG < timestamp) && (block.timestamp + MAX_LAG > timestamp);
    }

    function changeFeedRegistry(address newContractAddress) external onlyOwner {
        feedRegistry = IV1FeedRegistry(newContractAddress);
    }

    function changeTrustDomainRegistry(address newContractAddress) external onlyOwner {
        trustDomainRegistry = IV1TrustDomainRegistry(newContractAddress);
    }

    function addAllowedAddress(address address_) external onlyOwner {
        allowedAddresses[address_] = true;
    }

    function removeAllowedAddress(address address_) external onlyOwner {
        allowedAddresses[address_] = false;
    }
}
