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

    function testIsValidSubscription() public {
        vm.prank(owner);
        uint256 id = facet.createSubscription();

        // Initially, no consumers
        assertFalse(facet.isValidSubscription(id, user));

        // Add consumer
        vm.prank(owner);
        facet.addConsumer(id, user);

        // Now should be valid
        assertTrue(facet.isValidSubscription(id, user));

        // Remove consumer
        vm.prank(owner);
        facet.removeConsumer(id, user);

        // Should be invalid again
        assertFalse(facet.isValidSubscription(id, user));
    }

    function testReserveOnlyCallableInternally() public {
        vm.prank(owner);
        uint256 id = facet.createSubscription();
        facet.deposit{value: 1 ether}(id);

        vm.prank(address(facet));
        facet.reserve(id, 0.1 ether);

        vm.prank(address(owner));
        vm.expectRevert(IQuexActionRegistry.OnlyCallableInternally.selector);
        facet.reserve(id, 0.1 ether);
    }

    function testReleaseOnlyCallableInternally() public {
        vm.prank(owner);
        uint256 id = facet.createSubscription();
        facet.deposit{value: 1 ether}(id);

        vm.prank(address(owner));
        vm.expectRevert(IQuexActionRegistry.OnlyCallableInternally.selector);
        facet.release(id, 0.1 ether);
    }

    function testReleaseReducesReserved() public {
        vm.prank(owner);
        uint256 id = facet.createSubscription();
        facet.deposit{value: 1 ether}(id);

        vm.prank(address(facet));
        facet.reserve(id, 0.6 ether);

        // Check withdrawable balance after reserve
        uint256 withdrawableBefore = facet.withdrawableBalance(id);
        assertEq(withdrawableBefore, 0.4 ether);

        vm.prank(address(facet));
        facet.release(id, 0.3 ether);

        // Should have more withdrawable balance now
        uint256 withdrawableAfter = facet.withdrawableBalance(id);
        assertEq(withdrawableAfter, 0.7 ether);
    }

    function testFulfillReleasesReservedAndDecreasesBalance() public {
        vm.prank(owner);
        uint256 deposit = 1 ether;
        uint256 reservedFee = 0.25 ether;
        uint256 actualFee = 0.15 ether;
        uint256 locked = 0.51 ether;

        uint256 id = facet.createSubscription();
        facet.deposit{value: deposit}(id);

        vm.prank(address(facet));
        facet.reserve(id, reservedFee);

        vm.prank(owner);
        facet.lock(id, locked);

        uint256 startBalance = facet.balance(id);
        uint256 withdrawableBalance = facet.withdrawableBalance(id);

        assertEq(startBalance, deposit);
        assertEq(withdrawableBalance, deposit - reservedFee - locked);

        vm.prank(address(facet));
        facet.fulfill(id, reservedFee, actualFee);

        // Check that reserved is reduced, locked is reduced, balance is reduced
        assertEq(facet.balance(id), startBalance - actualFee, "Balance");
        assertEq(facet.withdrawableBalance(id), deposit - locked, "Withdrawable balance");
    }

    function testFulfillHandlesLowLockedAmount() public {
        vm.prank(owner);
        uint256 id = facet.createSubscription();
        facet.deposit{value: 1 ether}(id);

        // Reserve 0.2 ether
        vm.prank(address(facet));
        facet.reserve(id, 0.2 ether);

        // Lock only 0.1 ether
        vm.prank(owner);
        facet.lock(id, 0.1 ether);

        // Fulfill with reserved = 0.2 ether, actualFee = 0.3 ether
        vm.prank(address(facet));
        facet.fulfill(id, 0.2 ether, 0.3 ether);

        // Locked should now be 0 and balance reduced
        assertEq(facet.balance(id), 0.7 ether);
    }

    function testFulfillOnlyCallableInternally() public {
        vm.prank(owner);
        uint256 id = facet.createSubscription();
        facet.deposit{value: 1 ether}(id);

        vm.prank(owner);
        vm.expectRevert(IQuexActionRegistry.OnlyCallableInternally.selector);
        facet.fulfill(id, 0.1 ether, 0.2 ether);
    }
}
