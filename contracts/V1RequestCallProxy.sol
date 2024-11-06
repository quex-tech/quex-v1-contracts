// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/IV1RequestCallProxy.sol";
import "../interfaces/IV1RequestSpecRegistry.sol";
import "../interfaces/IV1TrustDomainRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract V1RequestCallProxy is IV1RequestCallProxy, Ownable {
    uint256 private requestCallIdNonce = 0;
    uint256 constant MAX_LAG = 30 minutes;

    mapping(address => bool) private allowedAddresses;

    IV1TrustDomainRegistry internal trustDomainRegistry;
    IV1RequestSpecRegistry internal requestSpecRegistry;

    event RequestCallCreated(bytes32 requestCallId, bytes32 requestSpecId);
    event RequestCallCompleted(
        bytes32 requestCallId,
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
        address requestSpecRegistryAddress,
        address trustDomainRegistryAddress
    ) Ownable(initialOwner) {
        requestSpecRegistry = IV1RequestSpecRegistry(requestSpecRegistryAddress);
        trustDomainRegistry = IV1TrustDomainRegistry(trustDomainRegistryAddress);
    }

    function calculateRequestCallPrice(uint32 callbackGasLimit) external view returns (uint256 requestCallPrice) {
        return callbackGasLimit * tx.gasprice;
    }

    function sendRequest(bytes32 requestSpecId) external onlyAllowed returns (bytes32 requestCallId) {
        (uint256 tdId, RequestSpec memory requestSpec) = requestSpecRegistry.getRequestSpec(requestSpecId);

        require(bytes(requestSpec.request.path).length > 0, "Request template doesn't exist");
        require(tdId == 0 || trustDomainRegistry.isAllowed(tdId), "Trust Domain is not allowed to use");

        requestCallId = _createRequestCallId(requestSpecId);
        emit RequestCallCreated(requestCallId, requestSpecId);

        return requestCallId;
    }

    function processResponse(
        bytes32 requestCallId,
        address callbackAddress,
        bytes4 callbackMethod,
        uint32 callbackGasLimit,
        RequestCallResult memory requestCallResult,
        address payable relayerAddress
    ) external payable onlyAllowed {
        require(trustDomainRegistry.isAllowed(requestCallResult.tdId), "Trust Domain is not allowed to use");
        require(_isTimestampValid(requestCallResult.dataItem.timestamp), "Time skew is too high");
        require(_isResultSignatureValid(requestCallResult), "Signature is not valid");

        bytes memory payload = abi.encodeWithSelector(callbackMethod, requestCallId, requestCallResult.dataItem);
        (bool success, ) = callbackAddress.call{gas: callbackGasLimit}(payload);

        relayerAddress.transfer(msg.value);
        emit RequestCallCompleted(
            requestCallId,
            relayerAddress,
            callbackAddress,
            callbackMethod,
            callbackGasLimit,
            success
        );
    }

    function _createRequestCallId(bytes32 requestSpecId) private returns (bytes32 requestCallId) {
        ++requestCallIdNonce;
        return keccak256(abi.encode(requestSpecId, msg.sender, block.timestamp, block.number, requestCallIdNonce));
    }

    function _isResultSignatureValid(RequestCallResult memory requestCallResult) private view returns (bool) {
        DataItem memory data = requestCallResult.dataItem;
        bytes memory message = abi.encode(data.timestamp, data.feedId, data.value);
        address signer = trustDomainRegistry.getSignerAddress(requestCallResult.tdId);
        ETHSignature memory signature = requestCallResult.signature;
        bytes32 messageHash = keccak256(message);
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        return ecrecover(ethSignedMessageHash, signature.v, signature.r, signature.s) == signer;
    }

    function _isTimestampValid(uint256 timestamp) private view returns (bool) {
        return (block.timestamp - MAX_LAG < timestamp) && (block.timestamp + MAX_LAG > timestamp);
    }

    function changeRequestSpecRegistry(address newContractAddress) external onlyOwner {
        requestSpecRegistry = IV1RequestSpecRegistry(newContractAddress);
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
