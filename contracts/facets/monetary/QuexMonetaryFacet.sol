// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../QuexRoles.sol";
import "./IQuexMonetaryFacet.sol";
import "./QuexMonetaryStorage.sol";

import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";

contract QuexMonetaryFacet is IQuexMonetary, AccessControlInternal {
    function getQuexFee(uint256 /* flowId */) external view returns (uint256) {
        return QuexMonetaryStorage.layout().constantQuexFee;
    }

    function getTreasury() external view returns (address) {
        return QuexMonetaryStorage.layout().treasuryAddress;
    }

    function setQuexFee(uint256 fee) external onlyRole(QuexRoles.MANAGER) {
        QuexMonetaryStorage.layout().constantQuexFee = fee;
    }

    function setTreasury(address treasuryAddress) external onlyRole(QuexRoles.MANAGER) {
        require(treasuryAddress != address(0), "Treasury cannot be zero address");
        QuexMonetaryStorage.layout().treasuryAddress = treasuryAddress;
    }
}
