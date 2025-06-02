// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import {DepositManagerFacet} from "../../../contracts/facets/monetary/DepositManagerFacet.sol";
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

    function testAddConsumerAndValidate() public {
        vm.prank(owner);
        uint256 id = facet.createSubscription();

        vm.prank(owner);
        facet.addConsumer(id, user);
        assertTrue(facet.isValidSubscription(id, user));
    }

    function testRemoveConsumerInvalidatesSubscription() public {
        vm.prank(owner);
        uint256 id = facet.createSubscription();

        vm.prank(owner);
        facet.addConsumer(id, user);
        assertTrue(facet.isValidSubscription(id, user));

        vm.prank(owner);
        facet.removeConsumer(id, user);
        assertFalse(facet.isValidSubscription(id, user));
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
}