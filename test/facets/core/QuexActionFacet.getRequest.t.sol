// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {QuexActionFacetTestDataBase} from "./QuexActionFacet.t.sol";
import {QuexActionFacet} from "../../../contracts/facets/actions/QuexActionFacet.sol";
import {Request, IdType, DataItem, OracleMessage, ETHSignature, IQuexActionRegistry} from "../../../contracts/interfaces/core/IQuexActionRegistry.sol";
import {Flow, IFlowRegistry} from "../../../contracts/interfaces/core/IFlowRegistry.sol";

contract QuexActionFacet_getRequest is QuexActionFacetTestDataBase {
    function test_ReturnsEmpty_IfUnknownRequest() public {
        Request memory request = testObject.getRequest(123456);
        vm.assertEq(request.requestId, 0);
        vm.assertEq(request.flowId, 0);
        vm.assertEq(request.oraclePool, address(0));
    }

    function test_ReturnsEmpty_IfRequestFulfilled() public {
        uint256 requestPrice = _getMinimumRequestPrice(flowId);
        uint256 requestId = testObject.createRequest(flowId, subscriptionId);
        TDTestData memory td = TD_validInQuex_inOraclePool;
        OracleMessage memory message = OracleMessage({
            actionId: actionId,
            dataItem: DataItem(vm.getBlockTimestamp(), 0, abi.encode(1)),
            relayer: relayer
        });
        ETHSignature memory signature = _signOracleMessage(message, td);
        _mockSuccessfulCallback(requestId, message.dataItem, IdType.RequestId);
        testObject.fulfillRequest(message, signature, requestId, td.tdId);

        Request memory request = testObject.getRequest(requestId);
        vm.assertEq(request.requestId, 0);
        vm.assertEq(request.flowId, 0);
        vm.assertEq(request.oraclePool, address(0));
    }

    function test_ReturnsRequest() public {
        uint256 requestPrice = _getMinimumRequestPrice(flowId);
        uint256 requestId = testObject.createRequest(flowId, subscriptionId);

        Request memory request = testObject.getRequest(requestId);
        vm.assertEq(request.requestId, requestId);
        vm.assertEq(request.flowId, flowId);
        vm.assertEq(request.oraclePool, oraclePoolAddress);
    }

    function _getMinimumRequestPrice(uint256 flowId) private view returns (uint256) {
        (uint256 nativeFee, uint256 gasFee) = testObject.getRequestFee(flowId);
        return nativeFee + gasFee * tx.gasprice;
    }
}