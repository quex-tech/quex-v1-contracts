// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import {DepositManagerFacet} from "../../../contracts/facets/monetary/DepositManagerFacet.sol";
import {DepositManagerStorage} from "../../../contracts/facets/monetary/DepositManagerStorage.sol";
import {IQuexActionRegistry} from "../../../contracts/interfaces/core/IQuexActionRegistry.sol";

contract DepositManagerFacetTest is Test {
    DepositManagerFacet facet;
    address owner = address(0x1);
    address user = address(0x2);

    function setUp() public {
        facet = new DepositManagerFacet();
        vm.deal(owner, 10 ether);
        vm.deal(user, 1 ether);
    }

    function testCreateSubscription() public {
        vm.prank(owner);
        uint256 id = facet.createSubscription();
        assertEq(facet.balance(id), 0);
    }

    function testDepositIncreasesBalance() public {
        vm.prank(owner);
        uint256 id = facet.createSubscription();

        vm.prank(owner);
        facet.deposit{value: 1 ether}(id);
        assertEq(facet.balance(id), 1 ether);

        facet.deposit{value: 1 ether}(id);
        assertEq(facet.balance(id), 2 ether);

    }

    function testWithdrawReducesBalance() public {
        vm.prank(owner);
        uint256 id = facet.createSubscription();

        vm.prank(owner);
        facet.deposit{value: 1 ether}(id);

        vm.prank(owner);
        facet.withdraw(id, owner);
        assertEq(facet.balance(id), 0);
    }

    function testSetOwnerRequiresOwnership() public {
        vm.prank(owner);
        uint256 id = facet.createSubscription();

        vm.prank(user);
        vm.expectRevert(IQuexActionRegistry.Subscription_WrongCaller.selector);
        facet.setOwner(id, user);
    }

    function testOnlyOwnerCanAddConsumer() public {
        vm.prank(owner);
        uint256 id = facet.createSubscription();

        vm.prank(user);
        vm.expectRevert(IQuexActionRegistry.Subscription_WrongCaller.selector);
        facet.addConsumer(id, user);
    }

    function testOnlyOwnerCanRemoveConsumer() public {
        vm.prank(owner);
        uint256 id = facet.createSubscription();
        vm.prank(owner);
        facet.addConsumer(id, user);

        vm.prank(user);
        vm.expectRevert(IQuexActionRegistry.Subscription_WrongCaller.selector);
        facet.removeConsumer(id, user);
    }

    function testLockIncreasesLockedAmount() public {
        vm.prank(owner);
        uint256 id = facet.createSubscription();
        uint256 v = 0.12 ether;
        uint256 lock = 0.02 ether;

        vm.prank(owner);
        facet.deposit{value: v}(id);
        assertEq(facet.withdrawableBalance(id), v);

        vm.prank(owner);
        facet.lock(id, lock);
        assertEq(facet.withdrawableBalance(id), v - lock);
    }

    function testOnlyOwnerCanLock() public {
        vm.prank(owner);
        uint256 id = facet.createSubscription();

        vm.prank(user);
        vm.expectRevert(IQuexActionRegistry.Subscription_WrongCaller.selector);
        facet.lock(id, 1 ether);
    }

}
