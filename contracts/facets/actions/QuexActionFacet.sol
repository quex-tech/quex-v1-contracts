// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../QuexRoles.sol";
import "../../interfaces/core/IFlowRegistry.sol";
import "../../interfaces/core/IOraclePool.sol";
import "../../interfaces/core/IQuexMonetary.sol";
import "./IQuexActionFacet.sol";
import "./QuexActionStorage.sol";

import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import {ECDSA} from "@solidstate/contracts/cryptography/ECDSA.sol";
import {ITrustDomainRegistry} from "../../interfaces/core/ITrustDomainRegistry.sol";

contract QuexActionFacet is IQuexActionFacet, AccessControlInternal, ReentrancyGuard {
    // push events
    event DataPushed(uint256 flowId, address sender);
    event DataPushingFailed(uint256 flowId, address sender);

    // request events
    event RequestFulfilled(uint256 requestId, uint256 flowId, address relayer);
    event RequestFulfillingFailed(uint256 requestId, uint256 flowId, address relayer);
    event RequestCancelled(uint256 requestId, uint256 flowId, address owner);

    function pushData(
        OracleMessage memory message,
        ETHSignature memory signature,
        uint256 flowId,
        uint256 tdId
    ) external payable nonReentrant {
        Flow memory flow = IFlowRegistry(address(this)).getFlow(flowId);
        _ensureOracleMessageIsValid(message, signature, flow, tdId);

        IQuexMonetary quexMonetary = IQuexMonetary(address(this));
        uint quexFee = quexMonetary.getQuexFee(flowId);
        if (msg.value < quexFee) {
            revert InsufficientValue();
        }

        payable(quexMonetary.getTreasury()).call{value: quexFee}("");
        if (msg.value > quexFee) {
            // todo: process situation when msg.sender is not payable
            payable(msg.sender).call{value: msg.value - quexFee}("");
        }

        bytes memory payload = abi.encodeWithSelector(flow.callback, flowId, message.dataItem, IdType.FlowId);
        (bool success, ) = flow.consumer.call{gas: flow.gasLimit}(payload);

        if (success) {
            emit DataPushed(flowId, msg.sender);
        } else {
            emit DataPushingFailed(flowId, msg.sender);
        }
    }

    function createRequest(uint256 flowId) external payable nonReentrant returns (uint256 requestId) {
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
            oraclePoolFee,
            block.number,
            msg.sender
        );

        if (msg.value > requestPrice) {
            // todo: process situation when msg.sender is not payable
            payable(msg.sender).call{value: msg.value - requestPrice}("");
        }

        return requestId;
    }

    function getRequest(uint256 requestId) external view returns (Request memory request) {
        QuexActionStorage.Request memory internalRequestModel = QuexActionStorage.layout().requests[requestId];
        if (internalRequestModel.flowId == 0) {
            return Request(0, 0, address(0), 0);
        }
        Flow memory flow = IFlowRegistry(address(this)).getFlow(internalRequestModel.flowId);
        return Request(requestId, internalRequestModel.flowId, flow.pool, internalRequestModel.createdBlockNumber);
    }

    function fulfillRequest(
        OracleMessage memory message,
        ETHSignature memory signature,
        uint256 requestId,
        uint256 tdId
    ) external nonReentrant {
        QuexActionStorage.Layout storage layout = QuexActionStorage.layout();
        QuexActionStorage.Request memory request = layout.requests[requestId];
        if (request.flowId == 0) {
            revert Request_NotFound();
        }
        delete layout.requests[requestId];

        Flow memory flow = IFlowRegistry(address(this)).getFlow(request.flowId);
        _ensureOracleMessageIsValid(message, signature, flow, tdId);

        IQuexMonetary quexMonetary = IQuexMonetary(address(this));
        payable(quexMonetary.getTreasury()).call{value: request.quexFee}("");
        payable(IOraclePool(flow.pool).getTreasury()).call{value: request.oraclePoolFee}("");
        payable(msg.sender).call{value: request.relayerPremium}("");

        bytes memory payload = abi.encodeWithSelector(flow.callback, requestId, message.dataItem, IdType.RequestId);
        (bool success, ) = flow.consumer.call{gas: flow.gasLimit}(payload);

        if (success) {
            emit RequestFulfilled(requestId, request.flowId, msg.sender);
        } else {
            emit RequestFulfillingFailed(requestId, request.flowId, msg.sender);
        }
    }

    function cancelRequest(uint256 requestId) external nonReentrant {
        QuexActionStorage.Layout storage layout = QuexActionStorage.layout();
        QuexActionStorage.Request memory request = layout.requests[requestId];
        if (request.flowId == 0) {
            revert Request_NotFound();
        }

        if (request.owner != msg.sender) {
            revert Request_NotOwnedBySender();
        }

        Flow memory flow = IFlowRegistry(address(this)).getFlow(request.flowId);
        uint256 maxResponseBlocks = IOraclePool(flow.pool).getMaxResponseBlocks();
        if (block.number - request.createdBlockNumber < maxResponseBlocks) {
            revert Request_TooFreshToCancel();
        }

        delete layout.requests[requestId];
        payable(msg.sender).call{value: request.quexFee + request.relayerPremium + request.oraclePoolFee}("");
        emit RequestCancelled(requestId, request.flowId, msg.sender);
    }

    function getQuexGas() external view returns (uint256) {
        return QuexActionStorage.layout().quexFulfillingGasCost;
    }

    function setQuexGas(uint256 quexGas) external onlyRole(QuexRoles.Manager) {
        QuexActionStorage.layout().quexFulfillingGasCost = quexGas;
    }

    function getRequestFee(uint256 flowId) external view returns (uint256 nativeFee, uint256 gasFee) {
        Flow memory flow = IFlowRegistry(address(this)).getFlow(flowId);
        uint256 quexFee = IQuexMonetary(address(this)).getQuexFee(flowId);
        uint256 oraclePoolFee = IOraclePool(flow.pool).getActionFee(flow.actionId);

        uint256 quexFulfillingGasCost = QuexActionStorage.layout().quexFulfillingGasCost;
        return (quexFee + oraclePoolFee, flow.gasLimit + quexFulfillingGasCost);
    }

    function getTimeSkew() external view returns (uint256 pastSkewInSeconds, uint256 futureSkewInSeconds) {
        QuexActionStorage.TimeSkewLayout storage timeSkewLayout = QuexActionStorage.timeSkewLayout();
        return (timeSkewLayout.timeSkewPast, timeSkewLayout.timeSkewFuture);
    }

    function setTimeSkew(uint256 pastSkewInSeconds, uint256 futureSkewInSeconds) external onlyRole(QuexRoles.Manager) {
        QuexActionStorage.TimeSkewLayout storage timeSkewLayout = QuexActionStorage.timeSkewLayout();
        timeSkewLayout.timeSkewPast = pastSkewInSeconds;
        timeSkewLayout.timeSkewFuture = futureSkewInSeconds;
    }

    function _ensureOracleMessageIsValid(
        OracleMessage memory message,
        ETHSignature memory signature,
        Flow memory flow,
        uint256 tdId
    ) private view {
        if (flow.pool == address(0)) {
            revert Flow_NotFound();
        }

        if (flow.actionId != message.actionId) {
            revert Action_MismatchIds();
        }

        QuexActionStorage.TimeSkewLayout storage timeSkewLayout = QuexActionStorage.timeSkewLayout();

        if (block.timestamp > message.dataItem.timestamp
            && block.timestamp - message.dataItem.timestamp > timeSkewLayout.timeSkewPast) {
            revert OracleMessage_OutdatedMessage();
        }

        if (message.dataItem.timestamp > block.timestamp
            && message.dataItem.timestamp - block.timestamp > timeSkewLayout.timeSkewFuture) {
            revert OracleMessage_TimestampFromFuture();
        }

        if (!ITrustDomainRegistry(address(this)).isTDValid(tdId)) {
            revert TrustDomain_NotValid();
        }

        if (!IOraclePool(address(flow.pool)).isInPool(tdId)) {
            revert TrustDomain_IsNotAllowedInOraclePool();
        }

        address tdAddress = ITrustDomainRegistry(address(this)).getTDSignerAddress(tdId);
        if (!_isSignatureValid(message, signature, tdAddress)) {
            revert OracleMessage_SignatureIsInvalid();
        }
    }

    function _isSignatureValid(
        OracleMessage memory oracleMessage,
        ETHSignature memory signature,
        address tdAddress
    ) private pure returns (bool) {
        bytes memory message = abi.encode(oracleMessage);
        bytes32 messageHash = keccak256(message);
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        return ECDSA.recover(ethSignedMessageHash, signature.v, signature.r, signature.s) == tdAddress;
    }
}
