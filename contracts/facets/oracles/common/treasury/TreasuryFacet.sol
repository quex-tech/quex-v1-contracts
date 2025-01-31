// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./TreasuryStorage.sol";
import "@solidstate/contracts/access/ownable/OwnableInternal.sol";

interface ITreasuryFacet {
    function getTreasury() external view returns (address);

    function setTreasury(address treasuryAddress) external;
}

contract TreasuryFacet is ITreasuryFacet, OwnableInternal {
    function getTreasury() external view returns (address) {
        return TreasuryStorage.layout().treasuryAddress;
    }

    function setTreasury(address treasuryAddress) external onlyOwner {
        TreasuryStorage.layout().treasuryAddress = treasuryAddress;
    }
}
