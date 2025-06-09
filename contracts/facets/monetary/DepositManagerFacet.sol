// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import {IDepositManager} from "../../interfaces/core/IDepositManager.sol";
import {DepositManagerStorage} from "./DepositManagerStorage.sol";
import {IQuexActionRegistry} from "../../../contracts/interfaces/core/IQuexActionRegistry.sol";

contract DepositManagerFacet is IDepositManager, ReentrancyGuard {

    modifier quexOnly() {
        if (msg.sender != address(this)) {
            revert IQuexActionRegistry.OnlyCallableInternally();
        }
        _;
    }

    event SubscriptionCreated(uint256 indexed id, address indexed owner);
    event OwnerUpdated(uint256 indexed id, address indexed owner);
    event ConsumerAdded(uint256 indexed id, address indexed consumer);
    event ConsumerRemoved(uint256 indexed id, address indexed consumer);

    function createSubscription() external override returns (uint256) {
        DepositManagerStorage.Layout storage l = DepositManagerStorage.layout();
        uint256 id = ++l.counter;
        l.subscriptions[id].owner = msg.sender;
        emit SubscriptionCreated(id, msg.sender);
        return id;
    }

    function setOwner(uint256 subscriptionId, address owner) external override {
        DepositManagerStorage.Layout storage l = DepositManagerStorage.layout();
        if (msg.sender != l.subscriptions[subscriptionId].owner) {
            revert IQuexActionRegistry.Subscription_WrongCaller();
        }
        l.subscriptions[subscriptionId].owner = owner;
        emit OwnerUpdated(subscriptionId, owner);
    }

    function deposit(uint256 subscriptionId) external payable override {
        DepositManagerStorage.Layout storage l = DepositManagerStorage.layout();
        l.subscriptions[subscriptionId].balance += msg.value;
    }

    function lock(uint256 subscriptionId, uint256 amount) external {
        DepositManagerStorage.Layout storage l = DepositManagerStorage.layout();
        DepositManagerStorage.Subscription storage s = l.subscriptions[subscriptionId];
        if (msg.sender != s.owner) {
            revert IQuexActionRegistry.Subscription_WrongCaller();
        }
        s.locked += amount;
    }

    function withdraw(uint256 subscriptionId, address receiver) external override nonReentrant {
        DepositManagerStorage.Layout storage l = DepositManagerStorage.layout();
        DepositManagerStorage.Subscription storage s = l.subscriptions[subscriptionId];
        if (msg.sender != s.owner) {
            revert IQuexActionRegistry.Subscription_WrongCaller();
        }

        uint256 withdrawable = this.withdrawableBalance(subscriptionId);
        if (withdrawable == 0) {
            revert IQuexActionRegistry.Subscription_InsufficientValue();
        }

        s.balance -= withdrawable;
        (bool success,) = receiver.call{value: withdrawable}("");
        if (!success) {
            revert IQuexActionRegistry.Subscription_TransferFailed();
        }
    }


    function addConsumer(uint256 subscriptionId, address consumer) external override {
        DepositManagerStorage.Layout storage l = DepositManagerStorage.layout();
        if (msg.sender != l.subscriptions[subscriptionId].owner) {
            revert IQuexActionRegistry.Subscription_WrongCaller();
        }
        l.subscriptions[subscriptionId].consumers[consumer] = true;
        emit ConsumerAdded(subscriptionId, consumer);
    }

    function removeConsumer(uint256 subscriptionId, address consumer) external override {
        DepositManagerStorage.Layout storage l = DepositManagerStorage.layout();
        if (msg.sender != l.subscriptions[subscriptionId].owner) {
            revert IQuexActionRegistry.Subscription_WrongCaller();
        }
        l.subscriptions[subscriptionId].consumers[consumer] = false;
        emit ConsumerRemoved(subscriptionId, consumer);
    }

    function balance(uint256 subscriptionId) external view override returns (uint256) {
        return DepositManagerStorage.layout().subscriptions[subscriptionId].balance;
    }

    function withdrawableBalance(uint256 subscriptionId) external view override returns (uint256) {
        DepositManagerStorage.Subscription storage s = DepositManagerStorage.layout().subscriptions[subscriptionId];
        return s.balance - s.reserved - s.locked;
    }

    function isValidSubscription(uint256 subscriptionId, address consumer) external view returns (bool) {
        DepositManagerStorage.Layout storage l = DepositManagerStorage.layout();
        return l.subscriptions[subscriptionId].consumers[consumer];
    }

    function reserve(uint256 subscriptionId, uint256 amount) external quexOnly {
        DepositManagerStorage.Layout storage l = DepositManagerStorage.layout();
        DepositManagerStorage.Subscription storage s = l.subscriptions[subscriptionId];
        if (s.balance - s.reserved < amount) {
            revert IQuexActionRegistry.Subscription_InsufficientValue();
        }
        s.reserved += amount;
    }

    function release(uint256 subscriptionId, uint256 amount) external quexOnly {
        DepositManagerStorage.Layout storage l = DepositManagerStorage.layout();
        DepositManagerStorage.Subscription storage s = l.subscriptions[subscriptionId];
        if (s.reserved < amount) {
            s.reserved = 0;
        } else {
            s.reserved -= amount;
        }
    }

    function fulfill(uint256 subscriptionId, uint256 reservedFee, uint256 actualFee) external quexOnly {
        DepositManagerStorage.Layout storage l = DepositManagerStorage.layout();
        DepositManagerStorage.Subscription storage s = l.subscriptions[subscriptionId];
        require(s.reserved >= reservedFee, "Trying to release funds that are not reserved");
        s.reserved -= reservedFee;

        if (s.locked >= actualFee) {
            s.locked -= actualFee;
        } else {
            s.locked = 0;
        }
        s.balance -= actualFee;
    }

}