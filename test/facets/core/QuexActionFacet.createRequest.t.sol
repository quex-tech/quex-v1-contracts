// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IQuexActionRegistry} from "../../../contracts/interfaces/core/IQuexActionRegistry.sol";
import {QuexActionFacetTestBase} from "./QuexActionFacet.t.sol";

contract QuexActionFacet_createRequest is QuexActionFacetTestBase {
    function setUp() public override {
        QuexActionFacetTestBase.setUp();
    }

    function test_EmitsRequestCreatedEvent() public {
        uint256 requestPrice = _getMinimumRequestPrice();

        vm.expectEmit(true, false, false, true);
        emit IQuexActionRegistry.RequestCreated(1, flowId, oraclePoolAddress);
        testObject.createRequest{value: requestPrice}(flowId);
    }

    function test_CreatesRequestWithDifferentIds() public {
        uint256 requestPrice = _getMinimumRequestPrice();
        uint256 requestId1 = testObject.createRequest{value: requestPrice}(flowId);
        uint256 requestId2 = testObject.createRequest{value: requestPrice}(flowId);
        assertNotEq(requestId1, requestId2);
    }

    function test_RevertsIf_InsufficientValue() public {
        uint256 requestPrice = _getMinimumRequestPrice();

        vm.expectRevert(IQuexActionRegistry.InsufficientValue.selector);
        testObject.createRequest{value: requestPrice - 1}(flowId);
    }

    function test_RevertsIf_FlowNotFound() public {
        uint256 requestPrice = _getMinimumRequestPrice();

        vm.expectRevert(IQuexActionRegistry.Flow_NotFound.selector);
        testObject.createRequest{value: requestPrice}(unknownFlowId);
    }

    function _getMinimumRequestPrice() private view returns (uint256) {
        (uint256 nativeFee, uint256 gasFee) = testObject.getRequestFee(flowId);
        return nativeFee + gasFee * tx.gasprice;
    }
}
