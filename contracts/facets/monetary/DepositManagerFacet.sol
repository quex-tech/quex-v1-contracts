// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { IDepositManager } from "../../interfaces/core/IDepositManager.sol";
import { DepositManagerStorage } from "./DepositManagerStorage.sol";

contract DepositManagerFacet is IDepositManager {
    event SubscriptionCreated(uint256 indexed id, address indexed owner);

    function createSubscription() external override returns (uint256) {
        DepositManagerStorage.Layout storage l = DepositManagerStorage.layout();
        uint256 id = ++l.counter;
        l.subscriptions[id].owner = msg.sender;
        emit SubscriptionCreated(id, msg.sender);
        return id;
    }

    function setOwner(uint256 subscriptionId, address owner) external override {
        DepositManagerStorage.Layout storage l = DepositManagerStorage.layout();
        require(msg.sender == l.subscriptions[subscriptionId].owner, "Not subscription owner");
        l.subscriptions[subscriptionId].owner = owner;
    }

    function deposit(uint256 subscriptionId) external payable override {
        DepositManagerStorage.Layout storage l = DepositManagerStorage.layout();
        l.subscriptions[subscriptionId].balance += msg.value;
    }

    function withdraw(uint256 subscriptionId, address receiver) external override {
        DepositManagerStorage.Layout storage l = DepositManagerStorage.layout();
        DepositManagerStorage.Subscription storage s = l.subscriptions[subscriptionId];
        require(msg.sender == s.owner, "Not subscription owner");

        uint256 withdrawable = s.balance - s.locked;
        require(withdrawable > 0, "Nothing to withdraw");

        s.balance -= withdrawable;
        (bool success, ) = receiver.call{value: withdrawable}("");
        require(success, "Transfer failed");
    }

    function lock(uint256 subscriptionId, uint256 amount) external override {
        DepositManagerStorage.Layout storage l = DepositManagerStorage.layout();
        DepositManagerStorage.Subscription storage s = l.subscriptions[subscriptionId];
        require(s.balance - s.locked >= amount, "Insufficient available balance");
        s.locked += amount;
    }

    function addConsumer(uint256 subscriptionId, address consumer) external override {
        DepositManagerStorage.Layout storage l = DepositManagerStorage.layout();
        require(msg.sender == l.subscriptions[subscriptionId].owner, "Not subscription owner");
        l.subscriptions[subscriptionId].consumers[consumer] = true;
    }

    function removeConsumer(uint256 subscriptionId, address consumer) external override {
        DepositManagerStorage.Layout storage l = DepositManagerStorage.layout();
        require(msg.sender == l.subscriptions[subscriptionId].owner, "Not subscription owner");
        l.subscriptions[subscriptionId].consumers[consumer] = false;
    }

    function balance(uint256 subscriptionId) external view override returns (uint256) {
        return DepositManagerStorage.layout().subscriptions[subscriptionId].balance;
    }

    function withdrawableBalance(uint256 subscriptionId) external view override returns (uint256) {
        DepositManagerStorage.Subscription storage s = DepositManagerStorage.layout().subscriptions[subscriptionId];
        return s.balance - s.locked;
    }
}