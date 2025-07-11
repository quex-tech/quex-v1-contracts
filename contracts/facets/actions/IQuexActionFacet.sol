// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IQuexActionRegistry} from "../../interfaces/core/IQuexActionRegistry.sol";

interface IQuexActionFacet is IQuexActionRegistry {
    function getQuexGas() external view returns (uint256);

    function setQuexGas(uint256 quexGas) external;

    function getTimeSkew() external view returns (uint256 pastSkewInSeconds, uint256 futureSkewInSeconds);

    function setTimeSkew(uint256 pastSkewInSeconds, uint256 futureSkewInSeconds) external;
}
