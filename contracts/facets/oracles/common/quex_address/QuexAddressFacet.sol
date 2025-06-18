// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../../../QuexRoles.sol";
import "./QuexAddressStorage.sol";
import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";

interface IQuexAddressFacet {
    function setQuexAddress(address quexAddress) external;

    function getQuexAddress() external view returns (address);
}

contract QuexAddressFacet is AccessControlInternal {
    function setQuexAddress(address quexAddress) external onlyRole(QuexRoles.Manager) {
        require(quexAddress != address(0), "Quex address cannot be 0");
        QuexAddressStorage.layout().quexAddress = quexAddress;
    }

    function getQuexAddress() external view returns (address) {
        return QuexAddressStorage.layout().quexAddress;
    }
}
