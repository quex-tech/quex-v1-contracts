// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../../../QuexRoles.sol";
import "./TreasuryStorage.sol";
import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";

interface ITreasuryFacet {
    function getTreasury() external view returns (address);

    function setTreasury(address treasuryAddress) external;
}

contract TreasuryFacet is ITreasuryFacet, AccessControlInternal {
    function getTreasury() external view returns (address) {
        return TreasuryStorage.layout().treasuryAddress;
    }

    function setTreasury(address treasuryAddress) external onlyRole(QuexRoles.Manager) {
        require(treasuryAddress != address(0), "Treasury cannot be zero address");
        TreasuryStorage.layout().treasuryAddress = treasuryAddress;
    }
}
