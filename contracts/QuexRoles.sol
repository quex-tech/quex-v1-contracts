// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

library QuexRoles {
    bytes32 constant public Manager = keccak256("quex.Manager");
    bytes32 constant public ManagerAdmin = keccak256("quex.ManagerAdmin");
}