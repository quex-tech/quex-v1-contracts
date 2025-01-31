// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../interfaces/core/IQuexMonetary.sol";

interface IQuexMonetaryFacet is IQuexMonetary {
    function setQuexFee(uint256 fee) external;
    function setTreasury(address treasuryAddress) external;
}
