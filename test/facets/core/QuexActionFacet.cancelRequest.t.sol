// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IQuexActionRegistry, Request} from "../../../contracts/interfaces/core/IQuexActionRegistry.sol";
import {IOraclePool} from "../../../contracts/interfaces/core/IOraclePool.sol";
import {Flow, IFlowRegistry} from "../../../contracts/interfaces/core/IFlowRegistry.sol";
import {QuexActionFacetTestBase} from "./QuexActionFacet.t.sol";
import {QuexActionFacet} from "../../../contracts/facets/actions/QuexActionFacet.sol";
import "forge-std/console.sol";

contract QuexActionFacet_cancelRequest is QuexActionFacetTestBase {
    uint256 internal requestId;
    uint256 internal requestPrice;
    address internal requestOwner;

    function setUp() public override {
        QuexActionFacetTestBase.setUp();
        requestOwner = address(this);
        requestPrice = _getMinimumRequestPrice();
        
        // Create a request that we can cancel
        requestId = testObject.createRequest{value: requestPrice}(flowId);
    }

    function test_SuccessfullyCancelsRequest() public {
        // Mock max response blocks to allow cancellation
        vm.mockCall(
            oraclePoolAddress,
            abi.encodeWithSelector(IOraclePool.getMaxResponseBlocks.selector),
            abi.encode(10)
        );

        // Move blocks forward to allow cancellation
        vm.roll(block.number + 11);

        // Get initial balance
        uint256 initialBalance = address(this).balance;

        // Cancel the request
        testObject.cancelRequest(requestId);

        // Verify request is deleted
        Request memory request = testObject.getRequest(requestId);
        assertEq(request.flowId, 0, "Request should be deleted");

        // Verify refund
        uint256 expectedRefund = requestPrice;
        assertLt(initialBalance + expectedRefund - address(this).balance, 200000, "Should receive full refund"); // 200000 is for gas costs
    }

    function test_RevertsIf_RequestNotFound() public {
        vm.expectRevert(IQuexActionRegistry.Request_NotFound.selector);
        testObject.cancelRequest(999); // Non-existent request ID
    }

    function test_RevertsIf_RequestTooFreshToCancel() public {
        // Mock max response blocks
        vm.mockCall(
            oraclePoolAddress,
            abi.encodeWithSelector(IOraclePool.getMaxResponseBlocks.selector),
            abi.encode(10)
        );

        // Try to cancel immediately
        vm.expectRevert(IQuexActionRegistry.Request_TooFreshToCancel.selector);
        testObject.cancelRequest(requestId);
    }

    function test_RevertsIf_NotRequestOwner() public {
        // Mock max response blocks to allow cancellation
        vm.mockCall(
            oraclePoolAddress,
            abi.encodeWithSelector(IOraclePool.getMaxResponseBlocks.selector),
            abi.encode(10)
        );

        // Move blocks forward to allow cancellation
        vm.roll(block.number + 11);

        // Try to cancel as different address
        vm.prank(address(0x123));
        vm.expectRevert(IQuexActionRegistry.Request_NotOwnedBySender.selector);
        testObject.cancelRequest(requestId);
    }

    function test_EmitsRequestCancelledEvent() public {
        // Mock max response blocks to allow cancellation
        vm.mockCall(
            oraclePoolAddress,
            abi.encodeWithSelector(IOraclePool.getMaxResponseBlocks.selector),
            abi.encode(10)
        );

        // Move blocks forward to allow cancellation
        vm.roll(block.number + 11);

        // Expect the RequestCancelled event
        vm.expectEmit(true, true, true, true);
        emit QuexActionFacet.RequestCancelled(requestId, flowId, requestOwner);

        // Cancel the request
        testObject.cancelRequest(requestId);
    }

    function _getMinimumRequestPrice() private view returns (uint256) {
        (uint256 nativeFee, uint256 gasFee) = testObject.getRequestFee(flowId);
        return nativeFee + gasFee * tx.gasprice;
    }
}
