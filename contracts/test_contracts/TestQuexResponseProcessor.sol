// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../interfaces/IV1RequestRegistry.sol";

contract TestQuexResponseProcessor {
    function goodProcessor(bytes32 requestId, DataItem memory response) external {}

    function errorProcessor(bytes32 requestId, DataItem memory response) external {
        require(false);
    }

    function badSignatureProcessor(DataItem memory response) external {}
}