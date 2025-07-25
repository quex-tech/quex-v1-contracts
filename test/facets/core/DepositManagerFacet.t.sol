// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import {DepositManagerFacet} from "../../../contracts/facets/monetary/DepositManagerFacet.sol";
import {IQuexActionRegistry} from "../../../contracts/interfaces/core/IQuexActionRegistry.sol";

contract DepositManagerFacetTest is Test {
    DepositManagerFacet facet;
    uint256 subscriptionId;
    address owner = address(0x1);
    address user = address(0x2);
    address receiver = address(0x3);

    function setUp() public {
        facet = new DepositManagerFacet();
        vm.deal(owner, 10 ether);
        vm.deal(user, 1 ether);

        vm.prank(owner);
        subscriptionId = facet.createSubscription();
        facet.deposit{value: 10 ether}(subscriptionId);
    }

    function test_createSubscription_CreatesSubscriptionWithZeroBalanceAndReserved() public {
        vm.prank(owner);
        uint256 id = facet.createSubscription();
        DepositManagerFacet.Subscription memory s = facet.getSubscription(id);
        assertEq(s.balance, 0);
        assertEq(s.reserved, 0);
    }

    function test_createSubscription_SetsOwner() public {
        vm.prank(owner);
        uint256 id = facet.createSubscription();
        DepositManagerFacet.Subscription memory s = facet.getSubscription(id);
        assertEq(s.owner, owner);
    }

    function test_deposit_IncreasesBalance() public {
        uint256 balance = facet.balance(subscriptionId);
        uint256 deposit = 1 ether;

        facet.deposit{value: deposit}(subscriptionId);
        assertEq(facet.balance(subscriptionId), balance + deposit);
    }

    function test_withdraw_WithdrawsAllBalance_IfNoReserved() public {
        DepositManagerFacet.Subscription memory s = facet.getSubscription(subscriptionId);
        assertEq(s.reserved, 0);

        uint256 facetBalanceBefore = address(facet).balance;
        uint256 subscriptionBalanceBefore = facet.balance(subscriptionId);
        uint256 toBalanceBefore = receiver.balance;

        vm.prank(owner);
        facet.withdraw(subscriptionId, receiver);
        assertEq(facet.balance(subscriptionId), 0);
        assertEq(address(facet).balance, facetBalanceBefore - subscriptionBalanceBefore);
        assertEq(receiver.balance, toBalanceBefore + subscriptionBalanceBefore);
    }

    function test_withdraw_WithdrawsNonReservedBalance_IfReserved() public {
        uint256 reserved = 1 ether;
        vm.prank(address(facet));
        facet.reserve(subscriptionId, reserved);

        uint256 subscriptionBalanceBefore = facet.balance(subscriptionId);
        uint256 withdrawable = facet.withdrawableBalance(subscriptionId);
        assertGt(subscriptionBalanceBefore, withdrawable);

        uint256 facetBalanceBefore = address(facet).balance;
        uint256 toBalanceBefore = receiver.balance;

        vm.prank(owner);
        facet.withdraw(subscriptionId, receiver);
        assertEq(facet.balance(subscriptionId), subscriptionBalanceBefore - withdrawable);
        assertEq(address(facet).balance, facetBalanceBefore - withdrawable);
        assertEq(receiver.balance, toBalanceBefore + withdrawable);
    }

    function test_withdraw_RevertsIfNotOwner() public {
        vm.prank(user);
        vm.expectRevert(IQuexActionRegistry.Subscription_WrongCaller.selector);
        facet.withdraw(subscriptionId, user);
    }

    function test_setOwner_RevertsIfNotOwner() public {
        vm.prank(user);
        vm.expectRevert(IQuexActionRegistry.Subscription_WrongCaller.selector);
        facet.setOwner(subscriptionId, user);
    }

    function test_setOwner_SetsOwner() public {
        vm.prank(owner);
        facet.setOwner(subscriptionId, user);

        assertEq(facet.getSubscription(subscriptionId).owner, user);
    }

    function test_addConsumer_RevertsIfNotOwner() public {
        vm.prank(user);
        vm.expectRevert(IQuexActionRegistry.Subscription_WrongCaller.selector);
        facet.addConsumer(subscriptionId, user);
    }

    function test_addConsumer_AddsConsumer() public {
        vm.prank(owner);
        facet.addConsumer(subscriptionId, user);

        assertEq(facet.hasAccessToSubscription(subscriptionId, user), true);
    }

    function test_addConsumer_DoesNotRevertIfConsumerAlreadyExists() public {
        vm.prank(owner);
        facet.addConsumer(subscriptionId, user);
        assertEq(facet.hasAccessToSubscription(subscriptionId, user), true);

        vm.prank(owner);
        facet.addConsumer(subscriptionId, user);
        assertEq(facet.hasAccessToSubscription(subscriptionId, user), true);
    }

    function test_removeConsumer_RevertsIfNotOwner() public {
        vm.prank(owner);
        uint256 id = facet.createSubscription();
        vm.prank(owner);
        facet.addConsumer(id, user);

        vm.prank(user);
        vm.expectRevert(IQuexActionRegistry.Subscription_WrongCaller.selector);
        facet.removeConsumer(id, user);
    }

    function test_removeConsumer_RemovesConsumer() public {
        vm.prank(owner);
        facet.addConsumer(subscriptionId, user);
        assertEq(facet.hasAccessToSubscription(subscriptionId, user), true);

        vm.prank(owner);
        facet.removeConsumer(subscriptionId, user);
        assertEq(facet.hasAccessToSubscription(subscriptionId, user), false);
    }

    function test_removeConsumer_DoesNotRevertIfConsumerDoesNotExist() public {
        assertEq(facet.hasAccessToSubscription(subscriptionId, user), false);
        vm.prank(owner);
        facet.removeConsumer(subscriptionId, user);
        assertEq(facet.hasAccessToSubscription(subscriptionId, user), false);
    }

    function test_reserve_RevertsIfNotInternalCall() public {
        vm.expectRevert(IQuexActionRegistry.OnlyCallableInternally.selector);
        facet.reserve(subscriptionId, 0.1 ether);
    }

    function test_reserve_Reserves() public {
        uint256 reserved = 1 ether;
        uint256 reservedBefore = facet.getSubscription(subscriptionId).reserved;

        vm.prank(address(facet));
        facet.reserve(subscriptionId, reserved);

        assertEq(facet.getSubscription(subscriptionId).reserved, reservedBefore + reserved);
    }

    function test_release_RevertsIfNotInternalCall() public {
        vm.expectRevert(IQuexActionRegistry.OnlyCallableInternally.selector);
        facet.release(subscriptionId, 0.1 ether);
    }

    function test_release_Releases() public {
        uint256 reserved = 2 ether;
        vm.prank(address(facet));
        facet.reserve(subscriptionId, reserved);

        assertEq(facet.getSubscription(subscriptionId).reserved, reserved);

        uint256 release = 1 ether;
        vm.prank(address(facet));
        facet.release(subscriptionId, release);

        assertEq(facet.getSubscription(subscriptionId).reserved, reserved - release);
    }

    function test_release_RevertsIfAmountIsGreaterThanReserved() public {
        uint256 reserved = facet.getSubscription(subscriptionId).reserved;
        vm.prank(address(facet));
        vm.expectRevert();
        facet.release(subscriptionId, reserved + 1 ether);
    }

    function test_fulfill_RevertsIfNotInternalCall() public {
        vm.expectRevert(IQuexActionRegistry.OnlyCallableInternally.selector);
        facet.fulfill(subscriptionId, 0.1 ether, 0.2 ether);
    }

    function test_fulfill_ReleasesReservedAndDecreasesBalance(uint256 actualFee) public {
        uint256 reserved = 1 ether;
        vm.assume(actualFee <= reserved);

        vm.prank(address(facet));
        facet.reserve(subscriptionId, reserved);

        uint256 reservedBefore = facet.getSubscription(subscriptionId).reserved;
        uint256 balanceBefore = facet.balance(subscriptionId);

        vm.prank(address(facet));
        facet.fulfill(subscriptionId, reserved, actualFee);

        assertEq(facet.getSubscription(subscriptionId).reserved, reservedBefore - reserved);
        assertEq(facet.balance(subscriptionId), balanceBefore - actualFee);
    }

    function test_withdrawableBalance_ReturnsBalanceMinusReserved(uint256 balance, uint256 reserved) public {
        vm.assume(balance < 100 ether);
        vm.assume(balance >= reserved);

        uint256 id = facet.createSubscription();

        facet.deposit{value: balance}(id);

        vm.prank(address(facet));
        facet.reserve(id, reserved);

        assertEq(facet.withdrawableBalance(id), balance - reserved);
    }
}
