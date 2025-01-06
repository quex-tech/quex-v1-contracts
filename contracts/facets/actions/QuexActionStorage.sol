// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./QuexActionModels.sol";

library QuexActionStorage {
    struct Request {
        uint256 flowId;
        uint256 quexFee;
        uint256 relayerPremium;
        uint256 oraclePoolFee;
    }

    struct RequestLayout {
        mapping(uint256 => Request) requests;
        uint256 requestIdNonce;
        uint256 quexFulfillingGasCost;
    }

    bytes32 internal constant REQUEST_STORAGE_SLOT = keccak256("quex.contracts.storage.Action.Request");

    function requestLayout() internal pure returns (RequestLayout storage l) {
        bytes32 slot = REQUEST_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
        return l;
    }
}
