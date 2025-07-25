// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {console} from "forge-std/console.sol";
import {IDepositManager} from "../../../contracts/interfaces/core/IDepositManager.sol";
import {QuexActionFacetTestDataBase} from "./QuexActionFacet.t.sol";
import {QuexActionFacet} from "../../../contracts/facets/actions/QuexActionFacet.sol";
import {
    IdType,
    DataItem,
    OracleMessage,
    ETHSignature,
    IQuexActionRegistry
} from "../../../contracts/interfaces/core/IQuexActionRegistry.sol";
import {Flow, IFlowRegistry} from "../../../contracts/interfaces/core/IFlowRegistry.sol";
import {IOraclePool} from "../../../contracts/interfaces/core/IOraclePool.sol";
import {ECDSA} from "@solidstate/contracts/cryptography/ECDSA.sol";

contract QuexActionFacetFulfillRequest is QuexActionFacetTestDataBase {
    uint256 private requestPrice;
    uint256 private requestId;
    TDTestData private td;
    OracleMessage private message;
    ETHSignature private signature;
    IDepositManager private depositManager;

    function setUp() public override {
        QuexActionFacetTestDataBase.setUp();
        requestPrice = _getMinimumRequestPrice(FLOW_ID);
        (requestId, td, message, signature) = _createRequest();
        depositManager = IDepositManager(address(diamond));
    }

    function test_CallsCallbackFunctionOnce() public {
        _mockSuccessfulCallback(requestId, message.dataItem, IdType.RequestId);

        vm.expectCall(
            consumerAddress, abi.encodeWithSelector(callbackSignature, requestId, message.dataItem, IdType.RequestId), 1
        );

        testObject.fulfillRequest(message, signature, requestId, td.tdId);
    }

    function test_TransfersTokensToQuex() public {
        _mockSuccessfulCallback(requestId, message.dataItem, IdType.RequestId);

        IDepositManager depositManager = IDepositManager(address(testObject));
        uint256 lockedBefore =
            depositManager.balance(subscriptionId) - depositManager.withdrawableBalance(subscriptionId);
        assertEq(lockedBefore, requestPrice, "Request price should be locked before fulfillment");
        uint256 initialBalance = quexTreasury.balance;

        testObject.fulfillRequest(message, signature, requestId, td.tdId);

        uint256 lockedAfter =
            depositManager.balance(subscriptionId) - depositManager.withdrawableBalance(subscriptionId);
        assertEq(lockedAfter, 0, "Locked balance should be zero after fulfillment");
        assertEq(quexTreasury.balance, initialBalance + QUEX_FEE);
    }

    function test_TransfersTokensToQuex_EvenIf_CallbackIsFailed() public {
        _mockRevertedCallback(requestId, message.dataItem, IdType.RequestId);

        uint256 initialBalance = quexTreasury.balance;
        testObject.fulfillRequest(message, signature, requestId, td.tdId);

        assertEq(quexTreasury.balance, initialBalance + QUEX_FEE);
    }

    function test_TransfersTokensToOraclePool() public {
        _mockSuccessfulCallback(requestId, message.dataItem, IdType.RequestId);

        uint256 initialBalance = oraclePoolTreasury.balance;
        testObject.fulfillRequest(message, signature, requestId, td.tdId);

        assertEq(oraclePoolTreasury.balance, initialBalance + ORACLE_POOL_FEE);
    }

    function test_TransfersTokensToOraclePool_EvenIf_CallbackIsFailed() public {
        _mockRevertedCallback(requestId, message.dataItem, IdType.RequestId);

        uint256 initialBalance = oraclePoolTreasury.balance;
        testObject.fulfillRequest(message, signature, requestId, td.tdId);

        assertEq(oraclePoolTreasury.balance, initialBalance + ORACLE_POOL_FEE);
    }

    function test_FallbackToQuexTreasury_If_OraclePoolTransferFails() public {
        _mockSuccessfulCallback(requestId, message.dataItem, IdType.RequestId);

        // Mock the oracle pool to return the non-payable address
        vm.mockCall(
            address(oraclePoolAddress),
            abi.encodeWithSelector(IOraclePool.getTreasury.selector),
            abi.encode(nonPayableAddress)
        );
        assertEq(IOraclePool(flow.pool).getTreasury(), nonPayableAddress);

        (, uint256 gasFee) = testObject.getRequestFee(FLOW_ID);
        uint256 expectedRelayerReward = gasFee * tx.gasprice * GAS_PRICE_MULTIPLIER;

        uint256 relayerInitialBalance = address(this).balance;
        uint256 treasuryInitialBalance = quexTreasury.balance;

        testObject.fulfillRequest(message, signature, requestId, td.tdId);

        assertEq(address(this).balance, relayerInitialBalance + expectedRelayerReward);
        assertEq(quexTreasury.balance, treasuryInitialBalance + ORACLE_POOL_FEE + QUEX_FEE);
    }

    function test_FallbackToQuexTreasury_If_RelayerTransferFails() public {
        _mockSuccessfulCallback(requestId, message.dataItem, IdType.RequestId);

        // Create non-payable relayer
        OracleMessage memory msgWithRelayer = OracleMessage(ACTION_ID, message.dataItem, nonPayableAddress);
        ETHSignature memory sig = _signOracleMessage(msgWithRelayer, td);

        uint256 treasuryInitialBalance = quexTreasury.balance;

        testObject.fulfillRequest(msgWithRelayer, sig, requestId, td.tdId);

        // gasFee is redirected to Quex treasury
        (, uint256 gasFee) = testObject.getRequestFee(FLOW_ID);
        uint256 expectedFallback = gasFee * tx.gasprice * GAS_PRICE_MULTIPLIER;
        assertEq(quexTreasury.balance, treasuryInitialBalance + expectedFallback + QUEX_FEE);
    }

    function test_RevertsIf_NotEnoughGasLeftForCallback() public {
        _mockSuccessfulCallback(requestId, message.dataItem, IdType.RequestId);

        // Set a small gas limit in the flow to trigger the internal check
        uint256 localFlowId = uint256(keccak256("test_RevertsIf_NotEnoughGasLeftForCallback_flowId"));
        uint256 localActionId = uint256(keccak256("test_RevertsIf_NotEnoughGasLeftForCallback_actionId"));
        Flow memory flow =
            Flow(5_000_000, localActionId, oraclePoolAddress, address(this), this.callback_HeavyComputation.selector);
        IDepositManager(address(diamond)).addConsumer(subscriptionId, flow.consumer);
        vm.mockCall(
            address(diamond), abi.encodeWithSelector(IFlowRegistry.getFlow.selector, localFlowId), abi.encode(flow)
        );

        uint256 reqId = testObject.createRequest(localFlowId, subscriptionId);
        TDTestData memory tdLocal = TD_validInQuex_inOraclePool;
        OracleMessage memory msg =
            OracleMessage(localActionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)), relayer);
        ETHSignature memory sig = _signOracleMessage(msg, tdLocal);

        vm.expectRevert("Not enough gas left to safely execute callback");
        testObject.fulfillRequest{gas: 5_000_100}(msg, sig, reqId, tdLocal.tdId);
    }

    function test_TransfersTokensToRelayer() public {
        _mockSuccessfulCallback(requestId, message.dataItem, IdType.RequestId);

        (, uint256 gasFee) = testObject.getRequestFee(FLOW_ID);

        uint256 initialBalance = address(this).balance;
        testObject.fulfillRequest(message, signature, requestId, td.tdId);

        assertEq(address(this).balance, initialBalance + gasFee * tx.gasprice * GAS_PRICE_MULTIPLIER);
    }

    function test_TransfersTokensToRelayer_EvenIf_CallbackIsFailed() public {
        _mockRevertedCallback(requestId, message.dataItem, IdType.RequestId);

        (, uint256 gasFee) = testObject.getRequestFee(FLOW_ID);

        uint256 initialBalance = address(this).balance;
        testObject.fulfillRequest(message, signature, requestId, td.tdId);

        assertEq(address(this).balance, initialBalance + gasFee * tx.gasprice * GAS_PRICE_MULTIPLIER);
    }

    function test_TransfersTokensToDifferentRelayer() public {
        address actualRelayer = address(0xBEEF);
        OracleMessage memory msgWithRelayer = OracleMessage(ACTION_ID, message.dataItem, actualRelayer);
        ETHSignature memory sig = _signOracleMessage(msgWithRelayer, td);

        _mockSuccessfulCallback(requestId, msgWithRelayer.dataItem, IdType.RequestId);

        uint256 initialBalance = actualRelayer.balance;

        testObject.fulfillRequest(msgWithRelayer, sig, requestId, td.tdId);

        uint256 expectedReward = requestPrice - QUEX_FEE - ORACLE_POOL_FEE;
        assertEq(actualRelayer.balance, initialBalance + expectedReward);
    }

    function test_EmitsRequestFulfilledEvent() public {
        _mockSuccessfulCallback(requestId, message.dataItem, IdType.RequestId);

        vm.expectEmit(true, false, false, true);
        emit QuexActionFacet.RequestFulfilled(requestId, FLOW_ID, address(this));
        testObject.fulfillRequest(message, signature, requestId, td.tdId);
    }

    function test_EmitsRequestFulfillingFailedEventIf_CallbackIsFailed() public {
        _mockRevertedCallback(requestId, message.dataItem, IdType.RequestId);

        vm.expectEmit(true, false, false, true);
        emit QuexActionFacet.RequestFulfillingFailed(requestId, FLOW_ID, address(this));
        testObject.fulfillRequest(message, signature, requestId, td.tdId);
    }

    function test_RevertsIf_RequestNotFound() public {
        vm.expectRevert(IQuexActionRegistry.Request_NotFound.selector);
        testObject.fulfillRequest(message, signature, requestId + 1, td.tdId);
    }

    function test_RevertsIf_ActionIdsMismatched() public {
        OracleMessage memory msgMismatched =
            OracleMessage(ACTION_ID + 1, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)), relayer);
        ETHSignature memory sig = _signOracleMessage(msgMismatched, td);

        vm.expectRevert(IQuexActionRegistry.Action_MismatchIds.selector);
        testObject.fulfillRequest(msgMismatched, sig, requestId, td.tdId);
    }

    function test_RevertsIf_TrustDomainIsNotValid() public {
        uint256 reqId = testObject.createRequest(FLOW_ID, subscriptionId);
        TDTestData memory tdNotValid = TD_notValidInQuex_inOraclePool;
        OracleMessage memory msg = OracleMessage(ACTION_ID, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)), relayer);
        ETHSignature memory sig = _signOracleMessage(msg, tdNotValid);

        vm.expectRevert(IQuexActionRegistry.TrustDomain_NotValid.selector);
        testObject.fulfillRequest(msg, sig, reqId, tdNotValid.tdId);
    }

    function test_RevertsIf_TrustDomainIsNotInOraclePool() public {
        uint256 reqId = testObject.createRequest(FLOW_ID, subscriptionId);
        TDTestData memory tdNotInOraclePool = TD_validInQuex_notInOraclePool;
        OracleMessage memory msg = OracleMessage(ACTION_ID, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)), relayer);
        ETHSignature memory sig = _signOracleMessage(msg, tdNotInOraclePool);

        vm.expectRevert(IQuexActionRegistry.TrustDomain_IsNotAllowedInOraclePool.selector);
        testObject.fulfillRequest(msg, sig, reqId, tdNotInOraclePool.tdId);
    }

    function test_RevertsIf_SignatureIsInvalid() public {
        TDTestData memory signerTD = TD_validInQuex_notInOraclePool;
        ETHSignature memory sig = _signOracleMessage(message, signerTD);

        vm.expectRevert(IQuexActionRegistry.OracleMessage_SignatureIsInvalid.selector);
        testObject.fulfillRequest(message, sig, requestId, td.tdId);
    }

    function test_RevertsIf_MessageIsOutdated() public {
        vm.warp(100000000); // set block's timestamp
        uint256 timestamp = vm.getBlockTimestamp() - PAST_TIME_SKEW - 1;
        OracleMessage memory msg = OracleMessage(ACTION_ID, DataItem(timestamp, 0, abi.encode(1)), relayer);
        ETHSignature memory sig = _signOracleMessage(msg, td);

        vm.expectRevert(IQuexActionRegistry.OracleMessage_OutdatedMessage.selector);
        testObject.fulfillRequest(msg, sig, requestId, td.tdId);
    }

    function test_RevertsIf_MessageFromFuture() public {
        uint256 timestamp = vm.getBlockTimestamp() + FUTURE_TIME_SKEW + 1;
        OracleMessage memory msg = OracleMessage(ACTION_ID, DataItem(timestamp, 0, abi.encode(1)), relayer);
        ETHSignature memory sig = _signOracleMessage(msg, td);

        vm.expectRevert(IQuexActionRegistry.OracleMessage_TimestampFromFuture.selector);
        testObject.fulfillRequest(msg, sig, requestId, td.tdId);
    }

    function test_CallbackFailIf_CallbackReenter() public {
        uint256 flowIdLocal = uint256(keccak256("test_RevertsIf_CallbackReenter_flowId"));
        uint256 actionIdLocal = uint256(keccak256("test_RevertsIf_CallbackReenter_actionId"));
        Flow memory flow =
            Flow(1000000, actionIdLocal, oraclePoolAddress, address(this), this.callback_Reenter.selector);
        IDepositManager(address(diamond)).addConsumer(subscriptionId, flow.consumer);

        vm.mockCall(
            address(diamond), abi.encodeWithSelector(IFlowRegistry.getFlow.selector, flowIdLocal), abi.encode(flow)
        );

        uint256 requestIdLocal = testObject.createRequest(flowIdLocal, subscriptionId);
        TDTestData memory tdLocal = TD_validInQuex_inOraclePool;
        OracleMessage memory messageLocal =
            OracleMessage(actionIdLocal, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)), relayer);
        ETHSignature memory signatureLocal = _signOracleMessage(messageLocal, tdLocal);

        vm.expectCall(address(testObject), abi.encodeWithSelector(testObject.fulfillRequest.selector), 2);

        vm.expectEmit(true, false, false, true);
        emit QuexActionFacet.RequestFulfillingFailed(requestIdLocal, flowIdLocal, address(this));

        testObject.fulfillRequest(messageLocal, signatureLocal, requestIdLocal, tdLocal.tdId);
    }

    function test_RevertsIf_SignatureIsMalleable() public {
        // Create a malleable signature by modifying the s value
        // In ECDSA, if (s > n/2) then s' = n - s is also a valid signature
        // We'll modify the s value to create a malleable signature
        uint256 n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141; // secp256k1 curve order
        bytes32 malleableS = bytes32(n - uint256(signature.s));

        // Create a new signature with the malleable s value
        ETHSignature memory malleableSignature = ETHSignature(signature.r, malleableS, signature.v == 27 ? 28 : 27);

        vm.expectRevert(ECDSA.ECDSA__InvalidS.selector);
        testObject.fulfillRequest(message, malleableSignature, requestId, td.tdId);
    }

    function test_RelayerRefundIsGreaterThanGasSpent() public {
        _runRefundComparisonTest(5_000_000);
    }

    function test_RelayerRefundIsGreaterThanGasSpentOnGasLimit() public {
        _runRefundComparisonTest(50_000);
    }

    function _runRefundComparisonTest(uint256 gasLimit) private {
        // Setup a new flow with a heavy callback
        uint256 localFlowId =
            uint256(keccak256(abi.encodePacked("test_RelayerRefundIsGreaterThanGasSpent_flowId", gasLimit)));
        uint256 localActionId =
            uint256(keccak256(abi.encodePacked("test_RelayerRefundIsGreaterThanGasSpent_actionId", gasLimit)));
        Flow memory heavyFlow =
            Flow(5_000_000, localActionId, oraclePoolAddress, address(this), this.callback_HeavyComputation.selector);
        IDepositManager(address(diamond)).addConsumer(subscriptionId, heavyFlow.consumer);

        vm.mockCall(
            address(diamond), abi.encodeWithSelector(IFlowRegistry.getFlow.selector, localFlowId), abi.encode(heavyFlow)
        );

        // Create request
        uint256 requestIdLocal = testObject.createRequest(localFlowId, subscriptionId);
        TDTestData memory tdLocal = TD_validInQuex_inOraclePool;
        OracleMessage memory messageLocal =
            OracleMessage(localActionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)), relayer);
        ETHSignature memory signatureLocal = _signOracleMessage(messageLocal, tdLocal);

        uint256 balanceBefore = relayer.balance;
        uint256 gasStart = gasleft();

        vm.prank(relayer);
        testObject.fulfillRequest(messageLocal, signatureLocal, requestIdLocal, tdLocal.tdId);

        uint256 gasUsed = gasStart - gasleft();
        uint256 balanceAfter = relayer.balance;
        uint256 refund = balanceAfter - balanceBefore;
        uint256 spent = gasUsed * tx.gasprice;

        console.log("!! gasUsed:", gasUsed);
        console.log("!! balanceBefore:", balanceBefore);
        console.log("!! balanceAfter:", balanceAfter);
        console.log("!! balance diff:", balanceAfter - balanceBefore);
        uint256 diff = refund > spent ? (refund - spent) / tx.gasprice : (spent - refund) / tx.gasprice;
        console.log("!! diff:", diff);
        assertGt(refund, spent, "Refund should exceed gas spent");
    }

    function callback_HeavyComputation(uint256, /*requestId*/ DataItem memory dataItem, IdType /*idType*/ ) public {
        uint256 gasStart = gasleft();
        bytes32 hash = keccak256(abi.encode(dataItem.timestamp));
        for (uint256 i = 0; i < 2000; i++) {
            hash = keccak256(abi.encode(hash, i));
        }
        require(hash != bytes32(0)); // Prevent optimizer from removing loop
        uint256 gasUsed = gasStart - gasleft();
        console.log("!! gasUsed:", gasUsed);
    }

    function callback_Reenter(uint256 requestId, DataItem memory dataItem, IdType /* idType */ ) public {
        uint256 actionIdLocal = IFlowRegistry(address(testObject)).getFlow(FLOW_ID).actionId;
        TDTestData memory tdLocal = TD_validInQuex_inOraclePool;

        OracleMessage memory messageLocal = OracleMessage(actionIdLocal, dataItem, relayer);
        ETHSignature memory signatureLocal = _signOracleMessage(messageLocal, tdLocal);

        testObject.fulfillRequest(messageLocal, signatureLocal, requestId, tdLocal.tdId);
    }

    function _getMinimumRequestPrice(uint256 flowId) private view returns (uint256) {
        (uint256 nativeFee, uint256 gasFee) = testObject.getRequestFee(flowId);
        return nativeFee + gasFee * tx.gasprice * GAS_PRICE_MULTIPLIER;
    }

    receive() external payable {}

    function _createRequest()
        private
        returns (uint256 requestId, TDTestData memory td, OracleMessage memory message, ETHSignature memory signature)
    {
        requestId = testObject.createRequest(FLOW_ID, subscriptionId);
        td = TD_validInQuex_inOraclePool;
        message = OracleMessage(ACTION_ID, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)), relayer);
        signature = _signOracleMessage(message, td);
    }
}
