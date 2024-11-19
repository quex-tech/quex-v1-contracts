// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/IV1RequestRegistry.sol";

interface IV1RequestLogic {
    function calculateRequestPrice(uint32 callbackGasLimit) external view returns (uint256 requestPrice);

    function sendRequest(bytes32 feedId) external returns (bytes32 requestId);

    function processResponse(
        bytes32 requestId,
        bytes32 feedId, 
        address callbackAddress,
        bytes4 callbackMethod,
        uint32 callbackGasLimit,
        RequestResult memory requestResult,
        address payable relayerAddress
    ) external payable;
}
