// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./IQuexMonetaryFacet.sol";
import "./QuexMonetaryStorage.sol";

import "@solidstate/contracts/access/ownable/OwnableInternal.sol";

contract QuexMonetaryFacet is IQuexMonetary, OwnableInternal {
    function getQuexFee(uint256 /* flowId */) external view returns (uint256) {
        return QuexMonetaryStorage.layout().constantQuexFee;
    }

    function getTreasury() external view returns (address) {
        return QuexMonetaryStorage.layout().treasuryAddress;
    }

    function setQuexFee(uint256 fee) external onlyOwner {
        QuexMonetaryStorage.layout().constantQuexFee = fee;
    }

    function setTreasury(address treasuryAddress) external onlyOwner {
        QuexMonetaryStorage.layout().treasuryAddress = treasuryAddress;
    }
}
