// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../core/IOraclePool.sol";
import "../flow/IFlowRegistry.sol";
import "../monetary/IQuexMonetary.sol";
import "./IQuexActionRegistry.sol";
import "./QuexActionModels.sol";
import "./QuexActionStorage.sol";

import "@solidstate/contracts/access/ownable/Ownable.sol";

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
        // todo: what we do with change? Transfer it back to msg sender?

        bytes memory payload = abi.encodeWithSelector(flow.callback, flowId, message.dataItem, IdType.FlowId);
        (bool success,) = flow.consumer.call{gas: flow.gasLimit}(payload);
        // todo: what we do if callback is failed?

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
        IQuexActionRegistry quexActions = IQuexActionRegistry(address(this));
        uint256 quexFee = quexMonetary.getQuexFee(flowId);
        uint256 relayerPremium = (flow.gasLimit + quexActions.getQuexGas()) * tx.gasprice;
        uint256 oraclePoolFee = IOraclePool(flow.pool).getActionFee(flow.actionId);
        uint256 requestPrice = quexFee + relayerPremium + oraclePoolFee;

        if (msg.value < requestPrice) {
            revert InsufficientValue();
        }

        requestId = _createRequestId(flowId, flow.pool);
        emit RequestCreated(requestId, flowId, flow.pool);

        QuexActionStorage.requestLayout().requests[requestId] = QuexActionStorage.Request(
            flowId,
            quexFee,
            relayerPremium,
            oraclePoolFee
        );

        // todo: what do we do with the change?
        if (msg.value > requestPrice) {
            // todo: process situation when msg.sender is not payable
            payable(msg.sender).transfer(msg.value - requestPrice);
        }

        return requestId;
    }

    function fulfillRequest(OracleMessage memory message, ETHSignature memory signature, uint256 requestId, address tdAddress) external {
        // todo: think between external call and storage usage
        QuexActionStorage.RequestLayout storage layout = QuexActionStorage.requestLayout();
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

    function getQuexGas() external view returns (uint256) {
        return QuexActionStorage.requestLayout().quexFulfillingGasCost;
    }

    function setQuexGas(uint quexGas) external onlyOwner {
        QuexActionStorage.requestLayout().quexFulfillingGasCost = quexGas;
    }

    // todo: maybe include gas payment here?
    function getRequestFee(uint256 flowId) external view returns (uint256) {
        Flow memory flow = IFlowRegistry(address(this)).getFlow(flowId);
        uint256 quexFee = IQuexMonetary(address(this)).getQuexFee(flowId);
        uint256 oraclePoolFee = IOraclePool(flow.pool).getActionFee(flow.actionId);
        return quexFee + oraclePoolFee;
    }

    function _ensureOracleMessageIsValid(OracleMessage memory message, ETHSignature memory signature, Flow memory flow, address tdAddress) private view {
        if (flow.pool == address(0)) {
            revert Flow_NotFound();
        }

        if (flow.actionId != message.actionId) {
            revert Action_MismatchIds();
        }

        // todo: check if TD is registered and still valid
        IOraclePool oraclePool = IOraclePool(address(flow.pool));
        if (!oraclePool.isInPool(tdAddress)) {
            revert TrustDomain_IsNotAllowedInOraclePool();
        }

        if (!_isSignatureValid(message, signature, tdAddress)) {
            revert OracleMessage_SignatureIsInvalid();
        }
    }

    function _isSignatureValid(OracleMessage memory oracleMessage, ETHSignature memory signature, address tdAddress) private pure returns (bool) {
        // todo: validate that message to sign in TD will be the same
        bytes memory message = abi.encode(oracleMessage);
        bytes32 messageHash = keccak256(message);
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        return ecrecover(ethSignedMessageHash, signature.v, signature.r, signature.s) == tdAddress;
    }

    function _calculateRequestPrice(uint32 callbackGasLimit) private view returns (uint256 requestPrice) {
        return callbackGasLimit * tx.gasprice;
    }

    function _createRequestId(uint256 flowId, address poolAddress) private returns (uint256 requestId) {
        // todo: maybe use consequent ids?
        QuexActionStorage.RequestLayout storage layout = QuexActionStorage.requestLayout();
        ++layout.requestIdNonce;
        return uint256(keccak256(abi.encode(flowId, poolAddress, msg.sender, block.timestamp, block.number, layout.requestIdNonce)));
    }
}