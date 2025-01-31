// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./ConstantPriceMonetaryStorage.sol";
import "@solidstate/contracts/access/ownable/OwnableInternal.sol";

interface IConstantPriceMonetaryFacet {
    function getActionFee(uint256 actionId) external view returns (uint256);
    function setActionFee(uint256 fee) external;
}

contract ConstantPriceMonetaryFacet is IConstantPriceMonetaryFacet, OwnableInternal {
    function getActionFee(uint256 /* actionId */) external view returns (uint256) {
        return ConstantPriceMonetaryStorage.layout().actionFee;
    }

    function setActionFee(uint256 fee) external onlyOwner {
        ConstantPriceMonetaryStorage.layout().actionFee = fee;
    }
}