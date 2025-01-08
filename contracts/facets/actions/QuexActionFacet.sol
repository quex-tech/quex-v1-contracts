// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../interfaces/core/IFlowRegistry.sol";
import "../../interfaces/core/IOraclePool.sol";
import "../../interfaces/core/IQuexMonetary.sol";
import "../../interfaces/core/IQuexActionRegistry.sol";
import "./QuexActionStorage.sol";

import "@solidstate/contracts/access/ownable/Ownable.sol";
import {ITrustDomainRegistry} from "../../interfaces/core/ITrustDomainRegistry.sol";

contract QuexActionFacet is IQuexActionRegistry, Ownable {
    // push events
    event DataPushed(uint256 flowId, address sender);
    event DataPushingFailed(uint256 flowId, address sender);

    // request events
    event RequestFulfilled(uint256 requestId, uint256 flowId, address relayer, bool isSuccessful, uint256 quexFee, uint256 oraclePoolFee, uint256 relayerPremium);

    function pushData(OracleMessage memory message, ETHSignature memory signature, uint256 flowId, address tdAddress) external payable {
        Flow memory flow = IFlowRegistry(address(this)).getFlow(flowId);
        _ensureOracleMessageIsValid(message, signature, flow, tdAddress);

        IQuexMonetary quexMonetary = IQuexMonetary(address(this));
        uint quexFee = quexMonetary.getQuexFee(flowId);
        if (msg.value < quexFee) {
            revert InsufficientValue();
        }

        payable(quexMonetary.getTreasury()).transfer(quexFee);
        if (msg.value > quexFee) {
            // todo: process situation when msg.sender is not payable
            payable(msg.sender).transfer(msg.value - quexFee);
        }

        bytes memory payload = abi.encodeWithSelector(flow.callback, flowId, message.dataItem, IdType.FlowId);
        (bool success,) = flow.consumer.call{gas: flow.gasLimit}(payload);

        if (success) {
            emit DataPushed(flowId, msg.sender);
        } else {
            emit DataPushingFailed(flowId, msg.sender);
        }
    }

    function createRequest(uint256 flowId) external payable returns (uint256 requestId) {
        Flow memory flow = IFlowRegistry(address(this)).getFlow(flowId);

        if (flow.pool == address(0)) {
            revert Flow_NotFound();
        }

        IQuexMonetary quexMonetary = IQuexMonetary(address(this));
        uint256 quexFee = quexMonetary.getQuexFee(flowId);
        uint256 relayerPremium = (flow.gasLimit + QuexActionStorage.layout().quexFulfillingGasCost) * tx.gasprice;
        uint256 oraclePoolFee = IOraclePool(flow.pool).getActionFee(flow.actionId);
        uint256 requestPrice = quexFee + relayerPremium + oraclePoolFee;

        if (msg.value < requestPrice) {
            revert InsufficientValue();
        }

        requestId = ++QuexActionStorage.layout().lastRequestId;
        emit RequestCreated(requestId, flowId, flow.pool);

        QuexActionStorage.layout().requests[requestId] = QuexActionStorage.Request(
            flowId,
            quexFee,
            relayerPremium,
            oraclePoolFee
        );

        if (msg.value > requestPrice) {
            // todo: process situation when msg.sender is not payable
            payable(msg.sender).transfer(msg.value - requestPrice);
        }

        return requestId;
    }

    function fulfillRequest(OracleMessage memory message, ETHSignature memory signature, uint256 requestId, address tdAddress) external {
        QuexActionStorage.Layout storage layout = QuexActionStorage.layout();
        QuexActionStorage.Request memory request = layout.requests[requestId];
        if (request.flowId == 0) {
            revert Request_NotFound();
        }
        delete layout.requests[requestId];

        Flow memory flow = IFlowRegistry(address(this)).getFlow(request.flowId);
        _ensureOracleMessageIsValid(message, signature, flow, tdAddress);

        IQuexMonetary quexMonetary = IQuexMonetary(address(this));
        payable(quexMonetary.getTreasury()).transfer(request.quexFee);
        payable(IOraclePool(flow.pool).getTreasury()).transfer(request.oraclePoolFee);
        payable(msg.sender).transfer(request.relayerPremium);

        bytes memory payload = abi.encodeWithSelector(flow.callback, requestId, message.dataItem, IdType.RequestId);
        (bool success,) = flow.consumer.call{gas: flow.gasLimit}(payload);

        emit RequestFulfilled(
            requestId,
            request.flowId,
            msg.sender,
            success,
            request.quexFee,
            request.oraclePoolFee,
            request.relayerPremium
        );
    }

    function getRequest(uint256 requestId) external view returns (QuexActionStorage.Request memory) {
        return QuexActionStorage.layout().requests[requestId];
    }

    function getQuexGas() external view returns (uint256) {
        return QuexActionStorage.layout().quexFulfillingGasCost;
    }

    function setQuexGas(uint256 quexGas) external onlyOwner {
        QuexActionStorage.layout().quexFulfillingGasCost = quexGas;
    }

    function getRequestFee(uint256 flowId) external view returns (uint256 nativeFee, uint256 gasFee) {
        Flow memory flow = IFlowRegistry(address(this)).getFlow(flowId);
        uint256 quexFee = IQuexMonetary(address(this)).getQuexFee(flowId);
        uint256 oraclePoolFee = IOraclePool(flow.pool).getActionFee(flow.actionId);

        uint256 quexFulfillingGasCost = QuexActionStorage.layout().quexFulfillingGasCost;
        return (quexFee + oraclePoolFee, flow.gasLimit + quexFulfillingGasCost);
    }

    function _ensureOracleMessageIsValid(OracleMessage memory message, ETHSignature memory signature, Flow memory flow, address tdAddress) private view {
        if (flow.pool == address(0)) {
            revert Flow_NotFound();
        }

        if (flow.actionId != message.actionId) {
            revert Action_MismatchIds();
        }

        if (ITrustDomainRegistry(address(this)).isTDValid(tdAddress)) {
            revert TrustDomain_NotValid();
        }

        if (!IOraclePool(address(flow.pool)).isInPool(tdAddress)) {
            revert TrustDomain_IsNotAllowedInOraclePool();
        }

        if (!_isSignatureValid(message, signature, tdAddress)) {
            revert OracleMessage_SignatureIsInvalid();
        }
    }

    function _isSignatureValid(OracleMessage memory oracleMessage, ETHSignature memory signature, address tdAddress) private pure returns (bool) {
        bytes memory message = abi.encode(oracleMessage);
        bytes32 messageHash = keccak256(message);
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        return ecrecover(ethSignedMessageHash, signature.v, signature.r, signature.s) == tdAddress;
    }
}