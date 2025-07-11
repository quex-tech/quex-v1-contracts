// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {QuexRoles} from "../../../../QuexRoles.sol";
import {TreasuryStorage} from "./TreasuryStorage.sol";
import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";

interface ITreasuryFacet {
    error Treasury_ZeroAddress();

    function getTreasury() external view returns (address);

    function setTreasury(address treasuryAddress) external;
}

contract TreasuryFacet is ITreasuryFacet, AccessControlInternal {
    function getTreasury() external view returns (address) {
        return TreasuryStorage.layout().treasuryAddress;
    }

    function setTreasury(address treasuryAddress) external onlyRole(QuexRoles.MANAGER) {
        if (treasuryAddress == address(0)) {
            revert Treasury_ZeroAddress();
        }
        TreasuryStorage.layout().treasuryAddress = treasuryAddress;
    }
}
