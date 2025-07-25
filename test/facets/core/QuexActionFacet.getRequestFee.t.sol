// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Flow, IFlowRegistry} from "../../../contracts/interfaces/core/IFlowRegistry.sol";
import {IQuexMonetary} from "../../../contracts/interfaces/core/IQuexMonetary.sol";
import {IOraclePool} from "../../../contracts/interfaces/core/IOraclePool.sol";
import {QuexActionFacetTestBase} from "./QuexActionFacet.t.sol";

contract QuexActionFacetGetRequestFee is QuexActionFacetTestBase {
    function testFuzz_ReturnsCorrectFee(uint256 quexFee, uint256 poolFee, uint256 quexGas, uint256 callbackGas) public {
        vm.assume(quexFee < 100 ether);
        vm.assume(poolFee < 100 ether);
        vm.assume(quexGas < 1_000_000);
        vm.assume(callbackGas < 10_000_000);

        uint256 actionId = 15;
        uint256 flowId = 1;
        Flow memory flow = Flow(callbackGas, actionId, oraclePoolAddress, consumerAddress, callbackSignature);

        vm.mockCall(address(diamond), abi.encodeWithSelector(IFlowRegistry.getFlow.selector, flowId), abi.encode(flow));

        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(IQuexMonetary.getQuexFee.selector, flowId),
            abi.encode(quexFee)
        );

        vm.mockCall(
            oraclePoolAddress,
            abi.encodeWithSelector(IOraclePool.getActionFee.selector, actionId),
            abi.encode(poolFee)
        );

        vm.prank(manager.addr);
        testObject.setQuexGas(quexGas);

        (uint256 nativeFee, uint256 gasFee) = testObject.getRequestFee(flowId);
        assertEq(nativeFee, quexFee + poolFee);
        assertEq(gasFee, quexGas + callbackGas);
    }
}
