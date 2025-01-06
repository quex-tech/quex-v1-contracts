// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./QuexActionModels.sol";

interface IQuexActionRegistry {
    error Flow_NotFound();
    error Request_NotFound();
    error Action_MismatchIds();
    error TrustDomain_IsNotAllowedInOraclePool();
    error OracleMessage_SignatureIsInvalid();
    error InsufficientValue();

    event RequestCreated(uint256 requestId, uint256 flowId, address oraclePool);

    function pushData(OracleMessage memory message, ETHSignature memory signature, uint256 flowId, address tdAddress) external payable;
    function createRequest(uint256 flowId) external payable returns (uint256 requestId);
    function fulfillRequest(OracleMessage memory message, ETHSignature memory signature, uint256 requestId, address tdAddress) external;

    function getQuexGas() external view returns (uint256);
}
