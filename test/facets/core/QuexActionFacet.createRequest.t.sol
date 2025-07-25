// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IDepositManager} from "../../../contracts/interfaces/core/IDepositManager.sol";
import {IQuexActionRegistry} from "../../../contracts/interfaces/core/IQuexActionRegistry.sol";
import {QuexActionFacetTestBase} from "./QuexActionFacet.t.sol";
import {console} from "forge-std/console.sol";

contract QuexActionFacetCreateRequest is QuexActionFacetTestBase {

    function setUp() public override {
        QuexActionFacetTestBase.setUp();
    }

    function test_EmitsRequestCreatedEvent() public {
        vm.expectEmit(true, false, false, true);
        emit IQuexActionRegistry.RequestCreated(1, flowId, oraclePoolAddress);
        testObject.createRequest(flowId, subscriptionId);
    }

    function test_CreatesRequestWithDifferentIds() public {
        uint256 requestId1 = testObject.createRequest(flowId, subscriptionId);
        uint256 requestId2 = testObject.createRequest(flowId, subscriptionId);
        assertNotEq(requestId1, requestId2);
    }

    function test_RevertsIf_InsufficientValue() public {
        uint256 zeroSubscriptionId = IDepositManager(address(diamond)).createSubscription();
        IDepositManager(address(diamond)).addConsumer(zeroSubscriptionId, address(this));
        vm.expectRevert(IQuexActionRegistry.Subscription_InsufficientValue.selector);
        testObject.createRequest(flowId, zeroSubscriptionId);
    }

    function test_RevertsIf_FlowNotFound() public {
        vm.expectRevert(IQuexActionRegistry.Flow_NotFound.selector);
        testObject.createRequest(unknownFlowId, subscriptionId);
    }
}

contract OraclePoolWithReenterToCreateRequest {
    address internal quexCoreAddress;
    uint256 internal flowId;
    uint256 internal subscriptionId;

    constructor(address quexCoreAddress_, uint256 flowId_) {
        quexCoreAddress = quexCoreAddress_;
        flowId = flowId_;
        console.log(quexCoreAddress);
        console.log(flowId);
    }

    function getActionFee(uint256) external returns (uint256) {
        console.log(quexCoreAddress);
        console.log(flowId);
        IQuexActionRegistry(quexCoreAddress).createRequest(flowId, subscriptionId);
        return 0;
    }
}
