// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./QuexActionModels.sol";

library QuexActionStorage {
    struct MonetaryLayout {
        address treasuryAddress;
        uint256 constantQuexFee;
    }

    struct FlowLayout {
        mapping(uint256 => Flow) flows;
        uint256 lastFlowId;
    }

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

    bytes32 internal constant MONETARY_STORAGE_SLOT = keccak256("quex.contracts.storage.Action.Monetary");
    bytes32 internal constant FLOW_STORAGE_SLOT = keccak256("quex.contracts.storage.Action.Flow");
    bytes32 internal constant REQUEST_STORAGE_SLOT = keccak256("quex.contracts.storage.Action.Request");

    function monetaryLayout() internal pure returns (MonetaryLayout storage l) {
        bytes32 slot = MONETARY_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function flowLayout() internal pure returns (FlowLayout storage l) {
        bytes32 slot = FLOW_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function requestLayout() internal pure returns (RequestLayout storage l) {
        bytes32 slot = REQUEST_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
