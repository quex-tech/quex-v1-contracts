// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../feed_registry/IFeedRegistry.sol";
import "../trust_domain_policy/IFeedTrustDomainPolicy.sol";

import "./IFeedRequestRegistryExtended.sol";
import "./RequestStorage.sol";


contract FeedRequestRegistryFacet is IFeedRequestRegistryExtended {
    uint256 constant private MAX_LAG = 30 minutes;

    error RequestNotFound();
    error FeedNotFound();
    error InsufficientValueSent();
    error SignatureIsInvalid();
    error TrustDomainNotFound();

    function sendFeedRequest(
        bytes32 feedId,
        address callbackAddress,
        bytes4 callbackMethod,
        uint32 callbackGasLimit
    ) external payable returns (bytes32 requestId, uint256 requestPrice) {
        requestPrice = _calculateRequestPrice(callbackGasLimit);
        require(msg.value >= requestPrice, "Insufficient value sent");

        (address tdAddress, Feed memory feed) = IFeedRegistry(address(this)).getFeed(feedId);

        require(bytes(feed.request.path).length > 0, "Feed doesn't exist");
        require(tdAddress == address(0) || IFeedTrustDomainPolicy(address(this)).isTDAllowedForFeed(tdAddress), "Trust Domain is not allowed to use");

        requestId = _createRequestId(feedId);
        emit FeedRequestCreated(requestId, feedId);

        RequestStorage.layout().requests[requestId] = RequestStorage.Request(feedId, callbackAddress, callbackMethod, callbackGasLimit, requestPrice);

        if (msg.value > requestPrice) {
            payable(msg.sender).transfer(msg.value - requestPrice);
        }

        return (requestId, requestPrice);
    }

    function processFeedResponse(bytes32 requestId, RequestResult memory requestResult) external {
        RequestStorage.Layout storage layout = RequestStorage.layout();
        RequestStorage.Request memory request = layout.requests[requestId];

        if (request.feedId == 0) {
            revert RequestNotFound();
        } 

        require(IFeedTrustDomainPolicy(address(this)).isTDAllowedForFeed(requestResult.tdAddress), "Trust Domain is not allowed to use");
        require(requestResult.dataItem.feedId == request.feedId, "Response feed id is different from request feed id");
        require(_isTimestampValid(requestResult.dataItem.timestamp), "Time skew is too high");
        require(_isResultSignatureValid(requestResult), "Signature is not valid");

        bytes memory payload = abi.encodeWithSelector(request.callbackMethod, requestId, requestResult.dataItem);
        (bool success, ) = request.callbackAddress.call{gas: request.callbackGasLimit}(payload);

        payable(msg.sender).transfer(request.price);
        emit FeedRequestCompleted(
            requestId,
            msg.sender,
            request.callbackAddress,
            request.callbackMethod,
            request.callbackGasLimit,
            success
        );
        delete layout.requests[requestId];
    }

    function _calculateRequestPrice(uint32 callbackGasLimit) private view returns (uint256 requestPrice) {
        return callbackGasLimit * tx.gasprice;
    }

    function _createRequestId(bytes32 feedId) private returns (bytes32 requestId) {
        RequestStorage.Layout storage layout = RequestStorage.layout();
        ++layout.requestIdNonce;
        return keccak256(abi.encode(feedId, msg.sender, block.timestamp, block.number, layout.requestIdNonce));
    }

    function _isResultSignatureValid(RequestResult memory requestResult) private pure returns (bool) {
        DataItem memory data = requestResult.dataItem;
        bytes memory message = abi.encode(data.timestamp, data.feedId, data.value);
        ETHSignature memory signature = requestResult.signature;
        bytes32 messageHash = keccak256(message);
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        return ecrecover(ethSignedMessageHash, signature.v, signature.r, signature.s) == requestResult.tdAddress;
    }

    function _isTimestampValid(uint256 timestamp) private view returns (bool) {
        return (block.timestamp - MAX_LAG < timestamp) && (block.timestamp + MAX_LAG > timestamp);
    }
}
