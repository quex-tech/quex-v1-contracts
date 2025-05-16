// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

library QuexActionStorage {
    struct Request {
        uint256 flowId;
        uint256 quexFee;
        uint256 relayerPremium;
        uint256 oraclePoolFee;
        uint256 createdBlockNumber;
        address owner;
    }

    struct Layout {
        mapping(uint256 => Request) requests;
        uint256 lastRequestId;
        uint256 quexFulfillingGasCost;
    }

    struct TimeSkewLayout {
        uint256 timeSkewPast;
        uint256 timeSkewFuture;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("quex.contracts.storage.Action");
    bytes32 internal constant TIME_SKEW_STORAGE_SLOT = keccak256("quex.contracts.storage.Action.TimeSkew");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
        return l;
    }

    function timeSkewLayout() internal pure returns (TimeSkewLayout storage l) {
        bytes32 slot = TIME_SKEW_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
        return l;
    }
}
