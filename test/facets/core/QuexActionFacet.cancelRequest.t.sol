// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IQuexActionRegistry, Request} from "../../../contracts/interfaces/core/IQuexActionRegistry.sol";
import {IOraclePool} from "../../../contracts/interfaces/core/IOraclePool.sol";
import {IDepositManager} from "../../../contracts/interfaces/core/IDepositManager.sol";
import {QuexActionFacetTestBase} from "./QuexActionFacet.t.sol";
import {QuexActionFacet} from "../../../contracts/facets/actions/QuexActionFacet.sol";
import {IQuexMonetary} from "../../../contracts/interfaces/core/IQuexMonetary.sol";

contract QuexActionFacetCancelRequest is QuexActionFacetTestBase {
    uint256 internal requestId;
    uint256 internal requestPrice;
    address internal requestOwner;

    function setUp() public override {
        QuexActionFacetTestBase.setUp();
        requestOwner = address(this);

        // Create a request that we can cancel
        requestId = testObject.createRequest(FLOW_ID, subscriptionId);
    }

    function test_SuccessfullyCancelsRequest() public {
        // Mock max response blocks to allow cancellation
        vm.mockCall(
            oraclePoolAddress,
            abi.encodeWithSelector(IOraclePool.getMaxResponseBlocks.selector),
            abi.encode(10)
        );

        // Ensure request exists and funds are locked
        Request memory preRequest = testObject.getRequest(requestId);
        assertEq(preRequest.flowId, FLOW_ID, "Request should exist before cancellation");

        uint256 quexFee = IQuexMonetary(address(testObject)).getQuexFee(FLOW_ID);
        uint256 relayerPremium = (flow.gasLimit + testObject.getQuexGas()) * tx.gasprice * GAS_PRICE_MULTIPLIER;
        uint256 oraclePoolFee = IOraclePool(flow.pool).getActionFee(flow.actionId);
        uint256 requestPrice = quexFee + relayerPremium + oraclePoolFee;

        uint256 lockedBefore = IDepositManager(address(testObject)).balance(subscriptionId) -
            IDepositManager(address(testObject)).withdrawableBalance(subscriptionId);
        assertEq(lockedBefore, requestPrice, "Funds should be locked before cancellation");

        // Move blocks forward to allow cancellation
        vm.roll(block.number + 11);

        // Cancel the request
        testObject.cancelRequest(requestId);

        // Ensure request is deleted
        Request memory postRequest = testObject.getRequest(requestId);
        assertEq(postRequest.flowId, 0, "Request should be deleted after cancellation");

        // Ensure funds are unlocked
        uint256 lockedAfter = IDepositManager(address(testObject)).balance(subscriptionId) -
            IDepositManager(address(testObject)).withdrawableBalance(subscriptionId);
        assertEq(lockedAfter, 0, "Funds should be unlocked after cancellation");
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
        emit QuexActionFacet.RequestCancelled(requestId, FLOW_ID, requestOwner);

        // Cancel the request
        testObject.cancelRequest(requestId);
    }
}
