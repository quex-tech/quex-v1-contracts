// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./QuexAddressStorage.sol";
import "@solidstate/contracts/access/ownable/Ownable.sol";

contract QuexAddressFacet is Ownable {
    function setQuexAddress(address quexAddress) external onlyOwner {
        QuexAddressStorage.layout().quexAddress = quexAddress;
    }

    function getQuexAddress() external view returns (address) {
        return QuexAddressStorage.layout().quexAddress;
    }
}