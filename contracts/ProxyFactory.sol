// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {MinimalProxyFactory} from "@solidstate/contracts/factory/MinimalProxyFactory.sol";

contract ProxyFactory
{
    event ProxyDeployed(address);

    function deployMinimalProxy(address target) external returns (address) {
        address proxyAddress = MinimalProxyFactory.deployMinimalProxy(target);
        emit ProxyDeployed(proxyAddress);
        return proxyAddress;
    }

    function deployMinimalProxy(address target, bytes32 salt) external returns (address) {
        address proxyAddress = MinimalProxyFactory.deployMinimalProxy(target, salt);
        emit ProxyDeployed(proxyAddress);
        return proxyAddress;
    }
}
