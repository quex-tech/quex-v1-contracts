// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Script.sol";
import "forge-std/Test.sol";
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
    uint256 patchTDId = 100;
    uint256 createdFlowId = 12345;

    function setUp() public virtual {
        diamond = new QuexDiamond();
        diamond.init(address(this));
        RequestActionFacet facet = new RequestActionFacet();
        IERC2535DiamondCutInternal.FacetCut[] memory cuts = new IERC2535DiamondCutInternal.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](9);

        selectors[0] = RequestActionFacet.addAction.selector;
        selectors[1] = RequestActionFacet.addActionByParts.selector;
        selectors[2] = RequestActionFacet.addJqFilter.selector;
        selectors[3] = RequestActionFacet.addPrivatePatch.selector;
        selectors[4] = RequestActionFacet.addRequest.selector;
        selectors[5] = RequestActionFacet.addResponseSchema.selector;
        selectors[6] = RequestActionFacet.getAction.selector;
        selectors[7] = RequestActionFacet.addPrivatePatchConsumer.selector;
        selectors[8] = RequestActionFacet.removePrivatePatchConsumer.selector;

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

    function testFuzz_addAction_emitsRequestActionAddedEvent(
        FuzzTestCase memory testCase,
        PatchFuzzTestCase memory patchTestCase,
        bool withPatch
    ) public {
        (RequestAction memory requestSpec, uint256 actionId) = _createRequestAction(testCase, patchTestCase, withPatch);

        vm.expectEmit(true, false, false, true);
        emit IRequestOraclePool.RequestActionAdded(actionId);
        testObject.addAction(requestSpec);
    }

    function testFuzz_addActionByParts_emitsRequestActionAddedEvent(
        FuzzTestCase memory testCase,
        PatchFuzzTestCase memory patchTestCase,
        bool withPatch
    ) public {
        (RequestAction memory requestSpec, uint256 actionId) = _createRequestAction(testCase, patchTestCase, withPatch);
        (bytes32 requestId, bytes32 patchId, bytes32 schemaId, bytes32 filterId) = _createRequestParts(requestSpec);

        vm.expectEmit(true, false, false, true);
        emit IRequestOraclePool.RequestActionAdded(actionId);
        testObject.addActionByParts(requestId, patchId, schemaId, filterId);
    }

    function testFuzz_addPrivatePatch_RevertsIf_ZeroTDId(
        FuzzTestCase memory testCase,
        PatchFuzzTestCase memory patchTestCase
    ) public {
        (RequestAction memory requestSpec, ) = _createRequestAction(testCase, patchTestCase, true);
        requestSpec.patch.tdAddress = address(0);
        vm.expectRevert();
        testObject.addPrivatePatch(requestSpec.patch);
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

    function testFuzz_addActionByParts_RevertsIf_PrivatePatchNotAuthorized(
        FuzzTestCase memory testCase,
        PatchFuzzTestCase memory patchTestCase
    ) public {
        (RequestAction memory requestSpec, uint256 actionId) = _createRequestAction(testCase, patchTestCase, true);
        (bytes32 requestId, bytes32 patchId, bytes32 schemaId, bytes32 filterId) = _createRequestParts(requestSpec);
        vm.prank(address(0x123));
        vm.expectRevert(abi.encodeWithSelector(IRequestOraclePool.PrivatePatchNotAuthorized.selector));
        testObject.addActionByParts(requestId, patchId, schemaId, filterId);
    }

    function testFuzz_addAction_RevertsIf_PrivatePatchNotAuthorized(
        FuzzTestCase memory testCase,
        PatchFuzzTestCase memory patchTestCase
    ) public {
        (RequestAction memory requestSpec, uint256 actionId) = _createRequestAction(testCase, patchTestCase, true);
        testObject.addPrivatePatch(requestSpec.patch);
        vm.prank(address(0x123));
        vm.expectRevert(abi.encodeWithSelector(IRequestOraclePool.PrivatePatchNotAuthorized.selector));
        testObject.addAction(requestSpec);
    }

    function testFuzz_addActionByParts_createsActionIfPatchConsumerSet(
        FuzzTestCase memory testCase,
        PatchFuzzTestCase memory patchTestCase
    ) public {
        address consumer = address(0x123);
        (RequestAction memory requestSpec, uint256 actionId) = _createRequestAction(testCase, patchTestCase, true);
        (bytes32 requestId, bytes32 patchId, bytes32 schemaId, bytes32 filterId) = _createRequestParts(requestSpec);
        testObject.addPrivatePatchConsumer(patchId, consumer);
        vm.prank(consumer);
        vm.expectEmit(true, false, false, true);
        emit IRequestOraclePool.RequestActionAdded(actionId);
        testObject.addActionByParts(requestId, patchId, schemaId, filterId);
    }

    function testFuzz_addAction_createsActionIfPatchConsumerSet(
        FuzzTestCase memory testCase,
        PatchFuzzTestCase memory patchTestCase
    ) public {
        address consumer = address(0x123);
        (RequestAction memory requestSpec, uint256 actionId) = _createRequestAction(testCase, patchTestCase, true);
        bytes32 patchId = testObject.addPrivatePatch(requestSpec.patch);
        testObject.addPrivatePatchConsumer(patchId, consumer);
        vm.prank(consumer);
        vm.expectEmit(true, false, false, true);
        emit IRequestOraclePool.RequestActionAdded(actionId);
        testObject.addAction(requestSpec);
    }

    function testFuzz_addActionByParts_RevertsIf_ConsumerWasRemoved(
        FuzzTestCase memory testCase,
        PatchFuzzTestCase memory patchTestCase
    ) public {
        address consumer = address(0x123);
        (RequestAction memory requestSpec, uint256 actionId) = _createRequestAction(testCase, patchTestCase, true);
        (bytes32 requestId, bytes32 patchId, bytes32 schemaId, bytes32 filterId) = _createRequestParts(requestSpec);
        testObject.addPrivatePatchConsumer(patchId, consumer);
        testObject.removePrivatePatchConsumer(patchId, consumer);
        vm.prank(consumer);
        vm.expectRevert(abi.encodeWithSelector(IRequestOraclePool.PrivatePatchNotAuthorized.selector));
        testObject.addActionByParts(requestId, patchId, schemaId, filterId);
    }

    function testFuzz_addActionByParts_Success_IfEmptyPatch(
        FuzzTestCase memory testCase,
        PatchFuzzTestCase memory patchTestCase
    ) public {
        (RequestAction memory requestSpec, uint256 actionId) = _createRequestAction(testCase, patchTestCase, false);
        (bytes32 requestId, bytes32 patchId, bytes32 schemaId, bytes32 filterId) = _createRequestParts(requestSpec);
        testObject.addActionByParts(requestId, patchId, schemaId, filterId);
        vm.prank(address(0x123));
        vm.expectEmit(true, false, false, true);
        emit IRequestOraclePool.RequestActionAdded(actionId);
        testObject.addActionByParts(requestId, patchId, schemaId, filterId);
    }

    function testFuzz_addAction_Success_IfEmptyPatch(
        FuzzTestCase memory testCase,
        PatchFuzzTestCase memory patchTestCase
    ) public {
        (RequestAction memory requestSpec, uint256 actionId) = _createRequestAction(testCase, patchTestCase, false);
        testObject.addAction(requestSpec);
        vm.prank(address(0x123));
        vm.expectEmit(true, false, false, true);
        emit IRequestOraclePool.RequestActionAdded(actionId);
        testObject.addAction(requestSpec);
    }

    function testFuzz_addAction_RevertsIf_ConsumerWasRemoved(
        FuzzTestCase memory testCase,
        PatchFuzzTestCase memory patchTestCase
    ) public {
        address consumer = address(0x123);
        (RequestAction memory requestSpec, uint256 actionId) = _createRequestAction(testCase, patchTestCase, true);
        bytes32 patchId = testObject.addPrivatePatch(requestSpec.patch);
        testObject.addPrivatePatchConsumer(patchId, consumer);
        testObject.removePrivatePatchConsumer(patchId, consumer);
        vm.prank(consumer);
        vm.expectRevert(abi.encodeWithSelector(IRequestOraclePool.PrivatePatchNotAuthorized.selector));
        testObject.addAction(requestSpec);
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
        address tdAddress;
    }

    HTTPPrivatePatch private emptyPatch =
        HTTPPrivatePatch("", new RequestHeaderPatch[](0), new QueryParameterPatch[](0), "", address(0));

    string[] private _randomKeys = ["key1", "key2", "key3", "key4", "key5", "key6", "key7", "key8", "key9", "key10"];
    string[] private _randomValues = ["val1", "val2", "val3", "val4", "val5", "val6", "val7", "val8", "val9", "val10"];

    function _createRequestAction(
        FuzzTestCase memory testCase,
        PatchFuzzTestCase memory patchTestCase,
        bool withPatch
    ) private view returns (RequestAction memory requestAction, uint256 actionId) {
        vm.assume(bytes(testCase.host).length > 0);
        vm.assume(bytes(testCase.filter).length > 0);
        vm.assume(bytes(testCase.schema).length > 0);
        vm.assume(patchTestCase.tdAddress != address(0));

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

            patch = HTTPPrivatePatch(
                patchTestCase.pathSuffix,
                patchHeaders,
                patchParameters,
                patchTestCase.body,
                patchTestCase.tdAddress
            );
        }

        actionId = uint256(keccak256(abi.encode(RequestAction(request, patch, testCase.schema, testCase.filter))));
        requestAction = RequestAction(request, patch, testCase.schema, testCase.filter);
        return (requestAction, actionId);
    }

    function _createRequestParts(
        RequestAction memory requestSpec
    ) private returns (bytes32 requestId, bytes32 patchId, bytes32 schemaId, bytes32 filterId) {
        requestId = testObject.addRequest(requestSpec.request);
        patchId = testObject.addPrivatePatch(requestSpec.patch);
        schemaId = testObject.addResponseSchema(requestSpec.responseSchema);
        filterId = testObject.addJqFilter(requestSpec.jqFilter);
        return (requestId, patchId, schemaId, filterId);
    }
}
