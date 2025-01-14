// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {console} from "forge-std/console.sol";
import {QuexActionFacetTestDataBase} from "./QuexActionFacet.t.sol";
import {QuexActionFacet} from "../../../contracts/facets/actions/QuexActionFacet.sol";
import {IdType, DataItem, OracleMessage, ETHSignature, IQuexActionRegistry} from "../../../contracts/interfaces/core/IQuexActionRegistry.sol";

contract QuexActionFacet_fulfillRequest is QuexActionFacetTestDataBase {
    uint256 requestPrice;

    function setUp() override public {
        QuexActionFacetTestDataBase.setUp();
        requestPrice = _getMinimumRequestPrice();
    }

    function test_CallsCallbackFunctionOnce() public {
        uint256 requestId = testObject.createRequest{value:requestPrice}(flowId);
        TDTestData memory td = TD_validInQuex_inOraclePool;
        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        _mockSuccessfulCallback(requestId, message.dataItem, IdType.RequestId);

        vm.expectCall(
            consumerAddress,
            abi.encodeWithSelector(callbackSignature, requestId, message.dataItem, IdType.RequestId),
            1
        );

        testObject.fulfillRequest(message, signature, requestId, td.tdAddress);
    }

    function test_TransfersTokensToQuex() public {
        uint256 requestId = testObject.createRequest{value:requestPrice}(flowId);
        TDTestData memory td = TD_validInQuex_inOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        _mockSuccessfulCallback(requestId, message.dataItem, IdType.RequestId);

        uint256 initialBalance = quexTreasury.balance;
        testObject.fulfillRequest(message, signature, requestId, td.tdAddress);

        assertEq(quexTreasury.balance, initialBalance + quexFee);
    }

    function test_TransfersTokensToQuex_EvenIf_CallbackIsFailed() public {
        uint256 requestId = testObject.createRequest{value:requestPrice}(flowId);
        TDTestData memory td = TD_validInQuex_inOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        _mockRevertedCallback(requestId, message.dataItem, IdType.RequestId);

        uint256 initialBalance = quexTreasury.balance;
        testObject.fulfillRequest(message, signature, requestId, td.tdAddress);

        assertEq(quexTreasury.balance, initialBalance + quexFee);
    }

    function test_TransfersTokensToOraclePool() public {
        uint256 requestId = testObject.createRequest{value:requestPrice}(flowId);
        TDTestData memory td = TD_validInQuex_inOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        _mockSuccessfulCallback(requestId, message.dataItem, IdType.RequestId);

        uint256 initialBalance = oraclePoolTreasury.balance;
        testObject.fulfillRequest(message, signature, requestId, td.tdAddress);

        assertEq(oraclePoolTreasury.balance, initialBalance + oraclePoolFee);
    }

    function test_TransfersTokensToOraclePool_EvenIf_CallbackIsFailed() public {
        uint256 requestId = testObject.createRequest{value:requestPrice}(flowId);
        TDTestData memory td = TD_validInQuex_inOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        _mockRevertedCallback(requestId, message.dataItem, IdType.RequestId);

        uint256 initialBalance = oraclePoolTreasury.balance;
        testObject.fulfillRequest(message, signature, requestId, td.tdAddress);

        assertEq(oraclePoolTreasury.balance, initialBalance + oraclePoolFee);
    }

    function test_TransfersTokensToRelayer() public {
        uint256 requestId = testObject.createRequest{value:requestPrice}(flowId);
        TDTestData memory td = TD_validInQuex_inOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        _mockSuccessfulCallback(requestId, message.dataItem, IdType.RequestId);

        (, uint256 gasFee) = testObject.getRequestFee(flowId);

        uint256 initialBalance = address(this).balance;
        testObject.fulfillRequest(message, signature, requestId, td.tdAddress);

        assertEq(address(this).balance, initialBalance + gasFee * tx.gasprice);
    }

    function test_TransfersTokensToRelayer_EvenIf_CallbackIsFailed() public {
        uint256 requestId = testObject.createRequest{value:requestPrice}(flowId);
        TDTestData memory td = TD_validInQuex_inOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        _mockRevertedCallback(requestId, message.dataItem, IdType.RequestId);

        (, uint256 gasFee) = testObject.getRequestFee(flowId);

        uint256 initialBalance = address(this).balance;
        testObject.fulfillRequest(message, signature, requestId, td.tdAddress);

        assertEq(address(this).balance, initialBalance + gasFee * tx.gasprice);
    }

    function test_EmitsRequestFulfilledEvent() public {
        uint256 requestId = testObject.createRequest{value:requestPrice}(flowId);
        TDTestData memory td = TD_validInQuex_inOraclePool;
        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        _mockSuccessfulCallback(requestId, message.dataItem, IdType.RequestId);

        vm.expectEmit(true, false, false, true);
        emit QuexActionFacet.RequestFulfilled(requestId, flowId, address(this));
        testObject.fulfillRequest(message, signature, requestId, td.tdAddress);
    }

    function test_EmitsRequestFulfillingFailedEventIf_CallbackIsFailed() public {
        uint256 requestId = testObject.createRequest{value:requestPrice}(flowId);
        TDTestData memory td = TD_validInQuex_inOraclePool;
        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        _mockRevertedCallback(requestId, message.dataItem, IdType.RequestId);

        vm.expectEmit(true, false, false, true);
        emit QuexActionFacet.RequestFulfillingFailed(requestId, flowId, address(this));
        testObject.fulfillRequest(message, signature, requestId, td.tdAddress);}

    function test_RevertsIf_RequestNotFound() public {
        uint256 requestId = testObject.createRequest{value:requestPrice}(flowId);
        TDTestData memory td = TD_validInQuex_inOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        vm.expectRevert(IQuexActionRegistry.Request_NotFound.selector);
        testObject.fulfillRequest(message, signature, requestId + 1, td.tdAddress);
    }

    function test_RevertsIf_ActionIdsMismatched() public {
        uint256 requestId = testObject.createRequest{value:requestPrice}(flowId);
        TDTestData memory td = TD_validInQuex_inOraclePool;

        OracleMessage memory message = OracleMessage(actionId + 1, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        vm.expectRevert(IQuexActionRegistry.Action_MismatchIds.selector);
        testObject.fulfillRequest(message, signature, requestId, td.tdAddress);
    }

    function test_RevertsIf_TrustDomainIsNotValid() public {
        uint256 requestId = testObject.createRequest{value:requestPrice}(flowId);
        TDTestData memory td = TD_notValidInQuex_inOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        vm.expectRevert(IQuexActionRegistry.TrustDomain_NotValid.selector);
        testObject.fulfillRequest(message, signature, requestId, td.tdAddress);
    }

    function test_RevertsIf_TrustDomainIsNotInOraclePool() public {
        uint256 requestId = testObject.createRequest{value:requestPrice}(flowId);
        TDTestData memory td = TD_validInQuex_notInOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        vm.expectRevert(IQuexActionRegistry.TrustDomain_IsNotAllowedInOraclePool.selector);
        testObject.fulfillRequest(message, signature, requestId, td.tdAddress);
    }

    function test_RevertsIf_SignatureIsInvalid() public {
        uint256 requestId = testObject.createRequest{value:requestPrice}(flowId);
        TDTestData memory td = TD_validInQuex_inOraclePool;
        TDTestData memory signerTD = TD_validInQuex_notInOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, signerTD);

        vm.expectRevert(IQuexActionRegistry.OracleMessage_SignatureIsInvalid.selector);
        testObject.fulfillRequest(message, signature, requestId, td.tdAddress);
    }

    function _getMinimumRequestPrice() private view returns (uint256) {
        (uint256 nativeFee, uint256 gasFee) = testObject.getRequestFee(flowId);
        return nativeFee + gasFee * tx.gasprice;
    }

    receive() external payable {}
}
