// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Script.sol";
import "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import "forge-std/console.sol";
import "@solidstate/contracts/interfaces/IERC2535DiamondCutInternal.sol";
import "@solidstate/contracts/cryptography/ECDSA.sol";
import {QuexActionFacet} from "../../../../contracts/facets/actions/QuexActionFacet.sol";
import {QuexDiamond} from "../../../../contracts/diamond/QuexDiamond.sol";
import {RequestActionFacet} from "../../../../contracts/facets/oracles/requests/RequestActionFacet.sol";
import {IQuexAddressRegistry} from "../../../../contracts/facets/oracles/common/quex_address/IQuexAddressRegistry.sol";
import {Flow, IFlowRegistry} from "../../../../contracts/interfaces/core/IFlowRegistry.sol";
import "../../../../contracts/interfaces/oracles/IRequestOraclePool.sol";

contract RequestActionFacetTest is Test {
    QuexDiamond internal diamond;
    IRequestOraclePool internal testObject;

    address internal quexCoreAddress = vm.createWallet("quexCore").addr;
    address patchTDAddress = address(100);
    uint256 createdFlowId = 12345;

    function setUp() public virtual {
        diamond = new QuexDiamond();
        diamond.init();
        RequestActionFacet facet = new RequestActionFacet();
        IERC2535DiamondCutInternal.FacetCut[] memory cuts = new IERC2535DiamondCutInternal.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](8);

        selectors[0] = RequestActionFacet.addFlow.selector;
        selectors[1] = RequestActionFacet.addJqFilter.selector;
        selectors[2] = RequestActionFacet.addPrivatePatch.selector;
        selectors[3] = RequestActionFacet.addRequest.selector;
        selectors[4] = RequestActionFacet.addResponseSchema.selector;
        selectors[5] = RequestActionFacet.startRequest.selector;
        selectors[6] = RequestActionFacet.getAction.selector;
        selectors[7] = RequestActionFacet.getActionTD.selector;

        cuts[0] = IERC2535DiamondCutInternal.FacetCut({
            target: address(facet),
            action: IERC2535DiamondCutInternal.FacetCutAction.ADD,
            selectors: selectors
        });

        diamond.diamondCut(cuts, address(0), "");
        testObject = IRequestOraclePool(address(diamond));

        vm.txGasPrice(1000);
        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(IQuexAddressRegistry.getQuexAddress.selector),
            abi.encode(quexCoreAddress)
        );
        vm.mockCall(
            address(quexCoreAddress),
            abi.encodeWithSelector(IFlowRegistry.createFlow.selector),
            abi.encode(createdFlowId)
        );
    }

    function testFuzz_addFlow_createsFlowInQuexCore(
        FuzzTestCase memory testCase,
        PatchFuzzTestCase memory patchTestCase,
        CallbackSpec memory callbackSpec,
        bool withPatch
    ) public {
        vm.assume(callbackSpec.consumer != address(0));
        RequestSpec memory requestSpec = _createRequestSpec(testCase, patchTestCase, withPatch);
        Flow memory expectedFlow = Flow(
            callbackSpec.gasLimit,
            requestSpec.actionId,
            address(diamond),
            callbackSpec.consumer,
            callbackSpec.callback
        );

        (bytes32 requestId, bytes32 patchId, bytes32 schemaId, bytes32 filterId) = _createRequestParts(requestSpec);

        vm.expectCall(quexCoreAddress, abi.encodeWithSelector(IFlowRegistry.createFlow.selector, expectedFlow), 1);
        testObject.addFlow(
            requestId,
            patchId,
            schemaId,
            filterId,
            callbackSpec.consumer,
            callbackSpec.callback,
            callbackSpec.gasLimit
        );
    }

    function testFuzz_addFlow_emitsFeedAddedEvent(
        FuzzTestCase memory testCase,
        PatchFuzzTestCase memory patchTestCase,
        CallbackSpec memory callbackSpec,
        bool withPatch
    ) public {
        vm.assume(callbackSpec.consumer != address(0));
        RequestSpec memory requestSpec = _createRequestSpec(testCase, patchTestCase, withPatch);
        (bytes32 requestId, bytes32 patchId, bytes32 schemaId, bytes32 filterId) = _createRequestParts(requestSpec);

        vm.expectEmit(true, false, false, true);
        emit IRequestOraclePool.RequestActionAdded(requestSpec.actionId);
        testObject.addFlow(
            requestId,
            patchId,
            schemaId,
            filterId,
            callbackSpec.consumer,
            callbackSpec.callback,
            callbackSpec.gasLimit
        );
    }

    function testFuzz_addPrivatePatch_RevertsIf_ZeroTDAddress(
        FuzzTestCase memory testCase,
        PatchFuzzTestCase memory patchTestCase
    ) public {
        RequestSpec memory requestSpec = _createRequestSpec(testCase, patchTestCase, true);
        vm.expectRevert();
        testObject.addPrivatePatch(address(0), requestSpec.patch);
    }

    function test_addRequest_RevertsIf_HostIsEmpty() public {
        HTTPRequest memory request = HTTPRequest(
            RequestMethod.Get,
            "",
            "",
            new RequestHeader[](0),
            new QueryParameter[](0),
            ""
        );
        vm.expectRevert();
        testObject.addRequest(request);
    }

    function test_addJqFilter_RevertsIf_Empty() public {
        vm.expectRevert();
        testObject.addJqFilter("");
    }

    function test_addResponseSchema_RevertsIf_Empty() public {
        vm.expectRevert();
        testObject.addResponseSchema("");
    }

    function testFuzz_getActionTD_ReturnsTDAddress_IfPatchExist_OtherwiseZeroAddress(
        FuzzTestCase memory testCase,
        PatchFuzzTestCase memory patchTestCase,
        CallbackSpec memory callbackSpec,
        bool withPatch
    ) public {
        vm.assume(callbackSpec.consumer != address(0));
        RequestSpec memory requestSpec = _createRequestSpec(testCase, patchTestCase, withPatch);
        (bytes32 requestId, bytes32 patchId, bytes32 schemaId, bytes32 filterId) = _createRequestParts(requestSpec);
        testObject.addFlow(
            requestId,
            patchId,
            schemaId,
            filterId,
            callbackSpec.consumer,
            callbackSpec.callback,
            callbackSpec.gasLimit
        );

        vm.assertEq(testObject.getActionTD(requestSpec.actionId), withPatch ? patchTDAddress : address(0));
    }

    struct FuzzTestCase {
        uint256 method;
        string host;
        string path;
        bytes body;
        uint256 headersCount;
        uint256 parametersCount;
        string filter;
        string schema;
    }

    struct PatchFuzzTestCase {
        bytes pathSuffix;
        bytes body;
        uint256 headersCount;
        uint256 parametersCount;
    }

    struct CallbackSpec {
        address consumer;
        bytes4 callback;
        uint256 gasLimit;
    }

    HTTPPrivatePatch private emptyPatch =
        HTTPPrivatePatch("", new RequestHeaderPatch[](0), new QueryParameterPatch[](0), "");

    string[] private _randomKeys = ["key1", "key2", "key3", "key4", "key5", "key6", "key7", "key8", "key9", "key10"];
    string[] private _randomValues = ["val1", "val2", "val3", "val4", "val5", "val6", "val7", "val8", "val9", "val10"];

    struct RequestSpec {
        HTTPRequest request;
        HTTPPrivatePatch patch;
        string schema;
        string filter;
        address tdAddress;
        uint256 actionId;
    }

    function _createRequestSpec(
        FuzzTestCase memory testCase,
        PatchFuzzTestCase memory patchTestCase,
        bool withPatch
    ) private view returns (RequestSpec memory) {
        vm.assume(bytes(testCase.host).length > 0);
        vm.assume(bytes(testCase.filter).length > 0);
        vm.assume(bytes(testCase.schema).length > 0);

        testCase.method %= 7;
        testCase.headersCount %= _randomKeys.length;
        testCase.parametersCount %= _randomKeys.length;
        patchTestCase.headersCount %= _randomKeys.length;
        patchTestCase.parametersCount %= _randomKeys.length;

        RequestHeader[] memory headers = new RequestHeader[](testCase.headersCount);
        for (uint256 i = 0; i < testCase.headersCount; ++i) {
            headers[i] = RequestHeader(_randomKeys[i], _randomValues[i]);
        }

        QueryParameter[] memory paremeters = new QueryParameter[](testCase.parametersCount);
        for (uint256 i = 0; i < testCase.parametersCount; ++i) {
            paremeters[i] = QueryParameter(_randomKeys[i], _randomValues[i]);
        }

        HTTPRequest memory request = HTTPRequest(
            RequestMethod(testCase.method),
            testCase.host,
            testCase.path,
            headers,
            paremeters,
            testCase.body
        );

        HTTPPrivatePatch memory patch = emptyPatch;

        if (withPatch) {
            RequestHeaderPatch[] memory patchHeaders = new RequestHeaderPatch[](patchTestCase.headersCount);
            for (uint256 i = 0; i < patchTestCase.headersCount; ++i) {
                patchHeaders[i] = RequestHeaderPatch(_randomKeys[i], bytes(_randomValues[i]));
            }

            QueryParameterPatch[] memory patchParameters = new QueryParameterPatch[](patchTestCase.parametersCount);
            for (uint256 i = 0; i < patchTestCase.parametersCount; ++i) {
                patchParameters[i] = QueryParameterPatch(_randomKeys[i], bytes(_randomValues[i]));
            }

            patch = HTTPPrivatePatch(patchTestCase.pathSuffix, patchHeaders, patchParameters, patchTestCase.body);
        }

        uint256 actionId = uint256(keccak256(abi.encode(request, patch, testCase.schema, testCase.filter)));

        return
            RequestSpec(
                request,
                patch,
                testCase.schema,
                testCase.filter,
                patchTDAddress,
                actionId
            );
    }

    function _createRequestParts(
        RequestSpec memory requestSpec
    ) private returns (bytes32 requestId, bytes32 patchId, bytes32 schemaId, bytes32 filterId) {
        requestId = testObject.addRequest(requestSpec.request);
        patchId = testObject.addPrivatePatch(requestSpec.tdAddress, requestSpec.patch);
        schemaId = testObject.addResponseSchema(requestSpec.schema);
        filterId = testObject.addJqFilter(requestSpec.filter);
        return (requestId, patchId, schemaId, filterId);
    }
}
