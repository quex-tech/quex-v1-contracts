// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IQuexAddressRegistry {
    function getQuexAddress() external view returns (address);
}
