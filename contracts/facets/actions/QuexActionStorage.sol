// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

library QuexActionStorage {
    struct Request {
        uint256 flowId;
        uint256 quexFee;
        uint256 relayerPremium;
        uint256 oraclePoolFee;
    }

    struct Layout {
        mapping(uint256 => Request) requests;
        uint256 requestIdNonce;
        uint256 quexFulfillingGasCost;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("quex.contracts.storage.Action");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
        return l;
    }
}
