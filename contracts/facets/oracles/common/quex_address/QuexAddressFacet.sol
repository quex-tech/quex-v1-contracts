// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {QuexRoles} from "../../../../QuexRoles.sol";
import {QuexAddressStorage} from "./QuexAddressStorage.sol";
import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";

interface IQuexAddressFacet {
    error QuexAddress_ZeroAddress();

    function setQuexAddress(address quexAddress) external;

    function getQuexAddress() external view returns (address);
}

contract QuexAddressFacet is AccessControlInternal {
    function setQuexAddress(address quexAddress) external onlyRole(QuexRoles.MANAGER) {
        if (quexAddress == address(0)) {
            revert QuexAddress_ZeroAddress();
        }
        QuexAddressStorage.layout().quexAddress = quexAddress;
    }

    function getQuexAddress() external view returns (address) {
        return QuexAddressStorage.layout().quexAddress;
    }
}
