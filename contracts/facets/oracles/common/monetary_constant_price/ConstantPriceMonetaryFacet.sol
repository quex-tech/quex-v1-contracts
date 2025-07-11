// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {QuexRoles} from "../../../../QuexRoles.sol";
import {ConstantPriceMonetaryStorage} from "./ConstantPriceMonetaryStorage.sol";
import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";

interface IConstantPriceMonetaryFacet {
    function getActionFee(uint256 actionId) external view returns (uint256);
    function setActionFee(uint256 fee) external;
}

contract ConstantPriceMonetaryFacet is IConstantPriceMonetaryFacet, AccessControlInternal {
    function getActionFee(uint256 /* actionId */) external view returns (uint256) {
        return ConstantPriceMonetaryStorage.layout().actionFee;
    }

    function setActionFee(uint256 fee) external onlyRole(QuexRoles.MANAGER) {
        ConstantPriceMonetaryStorage.layout().actionFee = fee;
    }
}