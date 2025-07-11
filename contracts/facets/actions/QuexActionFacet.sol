// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {QuexRoles} from "../../QuexRoles.sol";
import {IFlowRegistry, Flow} from "../../interfaces/core/IFlowRegistry.sol";
import {IOraclePool} from "../../interfaces/core/IOraclePool.sol";
import {IQuexMonetary} from "../../interfaces/core/IQuexMonetary.sol";
import {IQuexActionFacet} from "./IQuexActionFacet.sol";
import {QuexActionStorage} from "./QuexActionStorage.sol";
import {OracleMessage, ETHSignature, Request, IdType} from "../../interfaces/core/IQuexActionRegistry.sol";

import {DepositManagerFacet} from "../monetary/DepositManagerFacet.sol";
import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import {ECDSA} from "@solidstate/contracts/cryptography/ECDSA.sol";
import {ITrustDomainRegistry} from "../../interfaces/core/ITrustDomainRegistry.sol";

contract QuexActionFacet is IQuexActionFacet, AccessControlInternal, ReentrancyGuard {
    uint256 private constant RELAYER_GAS_OVERHEAD = 80_000;
    uint256 private constant GAS_PRICE_MULTIPLIER = 2;

    // push events
    event DataPushed(uint256 flowId, address sender);
    event DataPushingFailed(uint256 flowId, address sender);

    // request events
    event RequestFulfilled(uint256 requestId, uint256 flowId, address relayer);
    event RequestFulfillingFailed(uint256 requestId, uint256 flowId, address relayer);
    event RequestCancelled(uint256 requestId, uint256 flowId, address owner);

    function pushData(
        OracleMessage calldata message,
        ETHSignature calldata signature,
        uint256 flowId,
        uint256 tdId
    ) external payable nonReentrant {
        Flow memory flow = IFlowRegistry(address(this)).getFlow(flowId);
        _ensureOracleMessageIsValid(message, signature, flow, tdId);

        IQuexMonetary quexMonetary = IQuexMonetary(address(this));
        uint quexFee = quexMonetary.getQuexFee(flowId);
        if (msg.value < quexFee) {
            revert Subscription_InsufficientValue();
        }

        if (msg.value > quexFee) {
            (bool sent,) = payable(message.relayer).call{value: msg.value - quexFee}("");
            if (!sent) {
                quexFee = msg.value;
            }
        }
        payable(quexMonetary.getTreasury()).call{value: quexFee}("");

        bytes memory payload = abi.encodeWithSelector(flow.callback, flowId, message.dataItem, IdType.FlowId);
        bool success = _safeCallbackCall(flow.consumer, flow.gasLimit, payload);

        if (success) {
            emit DataPushed(flowId, message.relayer);
        } else {
            emit DataPushingFailed(flowId, message.relayer);
        }
    }

    function composeRequest(uint256 flowId, uint256 subscriptionId) private view returns (QuexActionStorage.Request memory request) {
        Flow memory flow = IFlowRegistry(address(this)).getFlow(flowId);

        if (flow.pool == address(0)) {
            revert Flow_NotFound();
        }
        if (!DepositManagerFacet(address(this)).hasAccessToSubscription(subscriptionId, msg.sender)) {
            revert Subscription_NotFound(subscriptionId, msg.sender);
        }

        IQuexMonetary quexMonetary = IQuexMonetary(address(this));
        (uint256 nativeFee, uint256 gasFee) = this.getRequestFee(flowId);
        uint256 quexFee = quexMonetary.getQuexFee(flowId);
        uint256 maxGasPrice = tx.gasprice * GAS_PRICE_MULTIPLIER;
        uint256 maxRelayerRefund = gasFee * maxGasPrice;
        uint256 oraclePoolFee = IOraclePool(flow.pool).getActionFee(flow.actionId);
        QuexActionStorage.Request memory req = QuexActionStorage.Request(
            flowId,
            subscriptionId,
            quexFee,
            maxRelayerRefund,
            oraclePoolFee,
            block.number,
            msg.sender
        );
        return req;
    }

    function reserveFunds(uint256 subscriptionId, QuexActionStorage.Request memory req) private returns (uint256 requestId) {
        uint256 totalFee = req.quexFee + req.maxRelayerRefund + req.oraclePoolFee;
        DepositManagerFacet(address(this)).reserve(subscriptionId, totalFee);
    }

    function saveRequest(QuexActionStorage.Request memory req) private returns (uint256 requestId) {
        requestId = ++QuexActionStorage.layout().lastRequestId;
        QuexActionStorage.layout().requests[requestId] = req;
        return requestId;
    }

    function createRequest(uint256 flowId, uint256 subscriptionId) public returns (uint256 requestId) {
        Flow memory flow = IFlowRegistry(address(this)).getFlow(flowId);
        QuexActionStorage.Request memory req = composeRequest(flowId, subscriptionId);
        reserveFunds(subscriptionId, req);
        requestId = saveRequest(req);
        emit RequestCreated(requestId, flowId, flow.pool);
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
        OracleMessage calldata message,
        ETHSignature calldata signature,
        uint256 requestId,
        uint256 tdId
    ) external nonReentrant {
        uint256 gasStart = gasleft();
        QuexActionStorage.Layout storage layout = QuexActionStorage.layout();
        QuexActionStorage.Request memory request = layout.requests[requestId];
        IQuexMonetary quexMonetary = IQuexMonetary(address(this));

        if (request.flowId == 0) {
            revert Request_NotFound();
        }
        delete layout.requests[requestId];

        Flow memory flow = IFlowRegistry(address(this)).getFlow(request.flowId);
        _ensureOracleMessageIsValid(message, signature, flow, tdId);

        uint256 quexFee = request.quexFee;
        (bool poolSent,) = payable(IOraclePool(flow.pool).getTreasury()).call{value: request.oraclePoolFee}("");
        if (!poolSent) {
            quexFee += request.oraclePoolFee;
        }
        uint256 staticFees = request.quexFee + request.oraclePoolFee;

        bytes memory payload = abi.encodeWithSelector(flow.callback, requestId, message.dataItem, IdType.RequestId);
        bool success = _safeCallbackCall(flow.consumer, flow.gasLimit, payload);
        if (success) {
            emit RequestFulfilled(requestId, request.flowId, msg.sender);
        } else {
            emit RequestFulfillingFailed(requestId, request.flowId, msg.sender);
        }

        // Refund relayer with the gas used.
        // All possible business logic should be before this line to calculate gas used correctly
        uint256 gasUsed = gasStart - gasleft();
        uint256 refund = (gasUsed + RELAYER_GAS_OVERHEAD) * tx.gasprice;
        if (refund > request.maxRelayerRefund) {
            refund = request.maxRelayerRefund;
        }
        (bool relayerSent,) = payable(message.relayer).call{value: refund}("");
        if (!relayerSent) {
            quexFee += refund;
        }
        payable(quexMonetary.getTreasury()).call{value: quexFee}("");

        // Release funds from reserve and decrease subscription balance
        uint256 actualFees = staticFees + refund;
        uint256 reservedFee = staticFees + request.maxRelayerRefund;
        DepositManagerFacet(address(this)).fulfill(request.subscriptionId, reservedFee, actualFees);
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
        uint256 maxResponseBlocks = IOraclePool(flow.pool).getMaxResponseBlocks(flow.actionId);
        if (block.number - request.createdBlockNumber < maxResponseBlocks) {
            revert Request_TooFreshToCancel();
        }

        delete layout.requests[requestId];
        uint256 requestPrice = request.quexFee + request.maxRelayerRefund + request.oraclePoolFee;
        DepositManagerFacet(address(this)).release(request.subscriptionId, requestPrice);

        emit RequestCancelled(requestId, request.flowId, msg.sender);
    }

    function getQuexGas() external view returns (uint256) {
        return QuexActionStorage.layout().quexFulfillingGasCost;
    }

    function setQuexGas(uint256 quexGas) external onlyRole(QuexRoles.MANAGER) {
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

    function setTimeSkew(uint256 pastSkewInSeconds, uint256 futureSkewInSeconds) external onlyRole(QuexRoles.MANAGER) {
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

    function _safeCallbackCall(address consumer, uint256 gasLimit, bytes memory payload) private returns (bool success) {
        if (gasleft() < gasLimit + gasLimit / 63) {
            revert Callback_NotEnoughGas();
        }
        (success,) = consumer.call{gas: gasLimit}(payload);
    }
}
