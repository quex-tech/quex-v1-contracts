// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./TreasuryStorage.sol";
import "@solidstate/contracts/access/ownable/Ownable.sol";

contract TreasuryFacet is Ownable {
    function getTreasury(uint256 actionId) external view returns (address) {
        return TreasuryStorage.layout().treasuryAddress;
    }

    function setTreasury(address treasuryAddress) external onlyOwner {
        TreasuryStorage.layout().treasuryAddress = treasuryAddress;
    }
}