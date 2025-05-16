// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../../../QuexRoles.sol";
import "./ConstantMaxResponseBlocksStorage.sol";
import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";

interface IConstantMaxResponseBlocksFacet {
    function getMaxResponseBlocks() external view returns (uint256);
    function setMaxResponseBlocks(uint256 maxResponseBlocks) external;
}

contract ConstantMaxResponseBlocksFacet is IConstantMaxResponseBlocksFacet, AccessControlInternal {
    function getMaxResponseBlocks() external view returns (uint256) {
        return ConstantMaxResponseBlocksStorage.layout().maxResponseBlocks;
    }

    function setMaxResponseBlocks(uint256 maxResponseBlocks) external onlyRole(QuexRoles.Manager) {
        ConstantMaxResponseBlocksStorage.layout().maxResponseBlocks = maxResponseBlocks;
    }
}
