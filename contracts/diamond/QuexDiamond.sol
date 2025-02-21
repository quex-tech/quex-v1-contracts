// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IOwnable, Ownable, OwnableInternal} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {ISafeOwnable, SafeOwnable} from "@solidstate/contracts/access/ownable/SafeOwnable.sol";
import {IERC2535DiamondCut} from "@solidstate/contracts/interfaces/IERC2535DiamondCut.sol";
import {IERC2535DiamondLoupe} from "@solidstate/contracts/interfaces/IERC2535DiamondLoupe.sol";
import {DiamondBase} from "@solidstate/contracts/proxy/diamond/base/DiamondBase.sol";
import {DiamondFallback, IDiamondFallback} from "@solidstate/contracts/proxy/diamond/fallback/DiamondFallback.sol";
import {DiamondReadable} from "@solidstate/contracts/proxy/diamond/readable/DiamondReadable.sol";

import {DiamondWritable} from "./DiamondWritable.sol";

import {AccessControl} from "@solidstate/contracts/access/access_control/AccessControl.sol";
import {Initializable} from "@solidstate/contracts/security/initializable/Initializable.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import {QuexRoles} from "../QuexRoles.sol";

contract QuexDiamond is
    DiamondBase,
    DiamondFallback,
    DiamondReadable,
    DiamondWritable,
    SafeOwnable,
    Initializable,
    AccessControl
{
    function init() external initializer {
        bytes4[] memory selectors = new bytes4[](18);
        uint256 selectorIndex;

        // register DiamondFallback

        selectors[selectorIndex++] = IDiamondFallback.getFallbackAddress.selector;
        selectors[selectorIndex++] = IDiamondFallback.setFallbackAddress.selector;

        // register DiamondWritable

        selectors[selectorIndex++] = IERC2535DiamondCut.diamondCut.selector;

        // register DiamondReadable

        selectors[selectorIndex++] = IERC2535DiamondLoupe.facets.selector;
        selectors[selectorIndex++] = IERC2535DiamondLoupe.facetFunctionSelectors.selector;
        selectors[selectorIndex++] = IERC2535DiamondLoupe.facetAddresses.selector;
        selectors[selectorIndex++] = IERC2535DiamondLoupe.facetAddress.selector;

        // register SafeOwnable

        selectors[selectorIndex++] = Ownable.owner.selector;
        selectors[selectorIndex++] = SafeOwnable.nomineeOwner.selector;
        selectors[selectorIndex++] = Ownable.transferOwnership.selector;
        selectors[selectorIndex++] = SafeOwnable.acceptOwnership.selector;

        // register AccessControl
        selectors[selectorIndex++] = AccessControl.grantRole.selector;
        selectors[selectorIndex++] = AccessControl.getRoleAdmin.selector;
        selectors[selectorIndex++] = AccessControl.getRoleMember.selector;
        selectors[selectorIndex++] = AccessControl.getRoleMemberCount.selector;
        selectors[selectorIndex++] = AccessControl.hasRole.selector;
        selectors[selectorIndex++] = AccessControl.renounceRole.selector;
        selectors[selectorIndex++] = AccessControl.revokeRole.selector;

        // diamond cut

        FacetCut[] memory facetCuts = new FacetCut[](1);

        facetCuts[0] = FacetCut({target: address(this), action: FacetCutAction.ADD, selectors: selectors});

        _diamondCut(facetCuts, address(0), "");

        // set owner

        _setOwner(msg.sender);
        _grantRole(QuexRoles.DefaultAdminRole, msg.sender);
    }

    receive() external payable {}

    function _transferOwnership(address account) internal virtual override(OwnableInternal, SafeOwnable) {
        super._transferOwnership(account);
    }

    /**
     * @inheritdoc DiamondFallback
     */
    function _getImplementation()
        internal
        view
        override(DiamondBase, DiamondFallback)
        returns (address implementation)
    {
        implementation = super._getImplementation();
    }
}
