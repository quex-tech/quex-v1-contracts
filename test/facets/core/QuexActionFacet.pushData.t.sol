// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {QuexActionFacetTestDataBase} from "./QuexActionFacet.t.sol";
import {QuexActionFacet} from "../../../contracts/facets/actions/QuexActionFacet.sol";
import {IdType, DataItem, OracleMessage, ETHSignature, IQuexActionRegistry} from "../../../contracts/interfaces/core/IQuexActionRegistry.sol";
import {Flow, IFlowRegistry} from "../../../contracts/interfaces/core/IFlowRegistry.sol";
import {ECDSA} from "@solidstate/contracts/cryptography/ECDSA.sol";
contract QuexActionFacet_pushData is QuexActionFacetTestDataBase {
    uint256 internal pushFee = quexFee;

    function test_CallsCallbackFunctionOnce() public {
        TDTestData memory td = TD_validInQuex_inOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        _mockSuccessfulCallback(flowId, message.dataItem, IdType.FlowId);

        vm.expectCall(
            consumerAddress,
            abi.encodeWithSelector(callbackSignature, flowId, message.dataItem, IdType.FlowId),
            1
        );

        testObject.pushData{value: pushFee}(message, signature, flowId, td.tdId);
    }

    function test_TransfersTokensToQuex() public {
        TDTestData memory td = TD_validInQuex_inOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        _mockSuccessfulCallback(flowId, message.dataItem, IdType.FlowId);

        uint256 initialQuexTreasuryBalance = quexTreasury.balance;
        testObject.pushData{value: pushFee}(message, signature, flowId, td.tdId);

        assertEq(quexTreasury.balance, initialQuexTreasuryBalance + quexFee);
    }

    function test_TransfersTokensToQuex_EvenIf_CallbackIsFailed() public {
        TDTestData memory td = TD_validInQuex_inOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        _mockRevertedCallback(flowId, message.dataItem, IdType.FlowId);

        uint256 initialQuexTreasuryBalance = quexTreasury.balance;
        testObject.pushData{value: pushFee}(message, signature, flowId, td.tdId);

        assertEq(quexTreasury.balance, initialQuexTreasuryBalance + quexFee);
    }

    function test_EmitsDataPushedEvent() public {
        TDTestData memory td = TD_validInQuex_inOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        _mockSuccessfulCallback(flowId, message.dataItem, IdType.FlowId);

        vm.expectEmit(true, false, false, true);
        emit QuexActionFacet.DataPushed(flowId, address(this));
        testObject.pushData{value: pushFee}(message, signature, flowId, td.tdId);
    }

    function test_EmitsDataPushingFailedEventIf_CallbackIsFailed() public {
        TDTestData memory td = TD_validInQuex_inOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        _mockRevertedCallback(flowId, message.dataItem, IdType.FlowId);

        vm.expectEmit(true, false, false, true);
        emit QuexActionFacet.DataPushingFailed(flowId, address(this));
        testObject.pushData{value: pushFee}(message, signature, flowId, td.tdId);
    }

    function test_RevertsIf_FlowNotFound() public {
        TDTestData memory td = TD_validInQuex_inOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        vm.expectRevert(IQuexActionRegistry.Flow_NotFound.selector);
        testObject.pushData{value: pushFee}(message, signature, unknownFlowId, td.tdId);
    }

    function test_RevertsIf_InsufficientFee() public {
        TDTestData memory td = TD_validInQuex_inOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        vm.expectRevert(IQuexActionRegistry.InsufficientValue.selector);
        testObject.pushData{value: pushFee - 1}(message, signature, flowId, td.tdId);
    }

    function test_RevertsIf_ActionIdsMismatched() public {
        TDTestData memory td = TD_validInQuex_inOraclePool;

        OracleMessage memory message = OracleMessage(actionId + 1, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        vm.expectRevert(IQuexActionRegistry.Action_MismatchIds.selector);
        testObject.pushData{value: pushFee}(message, signature, flowId, td.tdId);
    }

    function test_RevertsIf_TrustDomainIsNotValid() public {
        TDTestData memory td = TD_notValidInQuex_inOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        vm.expectRevert(IQuexActionRegistry.TrustDomain_NotValid.selector);
        testObject.pushData{value: pushFee}(message, signature, flowId, td.tdId);
    }

    function test_RevertsIf_TrustDomainIsNotInOraclePool() public {
        TDTestData memory td = TD_validInQuex_notInOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        vm.expectRevert(IQuexActionRegistry.TrustDomain_IsNotAllowedInOraclePool.selector);
        testObject.pushData{value: pushFee}(message, signature, flowId, td.tdId);
    }

    function test_RevertsIf_SignatureIsInvalid() public {
        TDTestData memory td = TD_validInQuex_inOraclePool;
        TDTestData memory signerTD = TD_validInQuex_notInOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, signerTD);

        vm.expectRevert(IQuexActionRegistry.OracleMessage_SignatureIsInvalid.selector);
        testObject.pushData{value: pushFee}(message, signature, flowId, td.tdId);
    }

    function test_CallbackFailIf_CallbackReenter() public {
        uint256 flowId = uint256(keccak256("test_RevertsIf_CallbackReenter_flowId"));
        uint256 actionId = uint256(keccak256("test_RevertsIf_CallbackReenter_actionId"));
        Flow memory flow = Flow(1000000, actionId, oraclePoolAddress, address(this), this.callback_Reenter.selector);
        vm.mockCall(address(diamond), abi.encodeWithSelector(IFlowRegistry.getFlow.selector, flowId), abi.encode(flow));

        TDTestData memory td = TD_validInQuex_inOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, td);

        vm.expectCall(
            address(testObject),
            abi.encodeWithSelector(testObject.pushData.selector),
            2
        );

        vm.expectEmit(true, false, false, true);
        emit QuexActionFacet.DataPushingFailed(flowId, address(this));

        testObject.pushData{value: pushFee}(message, signature, flowId, td.tdId);
    }

    function test_RevertsIf_SignatureIsMalleable() public {
        TDTestData memory td = TD_validInQuex_inOraclePool;
        TDTestData memory signerTD = TD_validInQuex_notInOraclePool;

        OracleMessage memory message = OracleMessage(actionId, DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)));
        ETHSignature memory signature = _signOracleMessage(message, signerTD);
 
        // Create a malleable signature by modifying the s value
        // In ECDSA, if (s > n/2) then s' = n - s is also a valid signature
        // We'll modify the s value to create a malleable signature
        uint256 n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141; // secp256k1 curve order
        bytes32 malleableS = bytes32(n - uint256(signature.s));
        
        // Create a new signature with the malleable s value
        ETHSignature memory malleableSignature = ETHSignature(
            signature.r,
            malleableS,
            signature.v == 27 ? 28 : 27
        );

        vm.expectRevert(ECDSA.ECDSA__InvalidS.selector);
        testObject.pushData{value: pushFee}(message, malleableSignature, flowId, td.tdId);
    }

    function callback_Reenter(uint256 flowId, DataItem memory dataItem, IdType /* idType */) public {
        uint256 actionId = IFlowRegistry(address(testObject)).getFlow(flowId).actionId;
        TDTestData memory td = TD_validInQuex_inOraclePool;

        OracleMessage memory message = OracleMessage(actionId, dataItem);
        ETHSignature memory signature = _signOracleMessage(message, td);

        testObject.pushData{value: pushFee}(message, signature, flowId, td.tdId);
    }
}
