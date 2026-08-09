// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import "@solidstate/contracts/interfaces/IERC2535DiamondCutInternal.sol";
import {QuexDiamond} from "../../../../contracts/diamond/QuexDiamond.sol";
import {BatchRequestActionFacet} from "../../../../contracts/facets/oracles/requests/BatchRequestActionFacet.sol";
import {RequestActionFacet} from "../../../../contracts/facets/oracles/requests/RequestActionFacet.sol";
import "../../../../contracts/interfaces/oracles/IBatchRequestOraclePool.sol";

contract BatchRequestActionFacetTest is Test {
    QuexDiamond internal diamond;
    IBatchRequestOraclePool internal testObject;

    // keccak256("quex.action.batchRequest.v1"), mirrors BatchRequestActionFacet.BATCH_ACTION_DOMAIN.
    bytes32 private constant BATCH_ACTION_DOMAIN =
        0x4968257a8b21d6e257aa6b1971196271874e7a3adcf04e8a66e5d0047185e744;

    function setUp() public virtual {
        diamond = new QuexDiamond();
        diamond.init(address(this));
        BatchRequestActionFacet facet = new BatchRequestActionFacet();
        IERC2535DiamondCutInternal.FacetCut[] memory cuts = new IERC2535DiamondCutInternal.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](8);

        selectors[0] = BatchRequestActionFacet.addBatchAction.selector;
        selectors[1] = BatchRequestActionFacet.addBatchActionByParts.selector;
        selectors[2] = BatchRequestActionFacet.getBatchAction.selector;
        selectors[3] = BatchRequestActionFacet.maxBatchSize.selector;
        selectors[4] = RequestActionFacet.addRequest.selector;
        selectors[5] = RequestActionFacet.addPrivatePatch.selector;
        selectors[6] = RequestActionFacet.addResponseSchema.selector;
        selectors[7] = RequestActionFacet.addJqFilter.selector;

        cuts[0] = IERC2535DiamondCutInternal.FacetCut({
            target: address(facet),
            action: IERC2535DiamondCutInternal.FacetCutAction.ADD,
            selectors: selectors
        });

        diamond.diamondCut(cuts, address(0), "");
        testObject = IBatchRequestOraclePool(address(diamond));
    }

    function test_maxBatchSize_returnsCap() public view {
        assertEq(testObject.maxBatchSize(), 8);
    }

    function test_addBatchAction_emitsBatchRequestActionAddedEvent() public {
        BatchRequestAction memory batchAction = _createBatchAction(2);

        vm.expectEmit(true, false, false, false);
        emit IBatchRequestOraclePool.BatchRequestActionAdded(_actionId(batchAction));
        testObject.addBatchAction(batchAction);
    }

    function test_getBatchAction_returnsEncodedActionAfterAdd() public {
        BatchRequestAction memory batchAction = _createBatchAction(2);

        uint256 actionId = testObject.addBatchAction(batchAction);

        assertEq(testObject.getBatchAction(actionId), abi.encode(batchAction));
    }

    function test_addBatchAction_roundTripsRealPatches() public {
        BatchRequestAction memory batchAction = _createBatchAction(2);
        batchAction.patches[0] = _realPatch(address(0xBEEF));

        uint256 actionId = testObject.addBatchAction(batchAction);

        assertEq(testObject.getBatchAction(actionId), abi.encode(batchAction));
    }

    function test_addBatchAction_canonicalizesEmptyPatchWithTdAddress() public {
        // A content-empty patch carrying a non-zero tdAddress is dropped at registration (patchId == 0).
        // The committed id and getBatchAction output must reflect the canonical (dropped) form.
        BatchRequestAction memory batchAction = _createBatchAction(1);
        batchAction.patches[0].tdAddress = address(0xBEEF);

        BatchRequestAction memory canonical = _createBatchAction(1);

        uint256 actionId = testObject.addBatchAction(batchAction);

        assertEq(actionId, _actionId(canonical));
        assertEq(testObject.getBatchAction(actionId), abi.encode(canonical));
    }

    function test_addBatchActionByParts_emitsBatchRequestActionAddedEvent() public {
        BatchRequestAction memory batchAction = _createBatchAction(2);
        (bytes32[] memory requestIds, bytes32[] memory patchIds, bytes32 schemaId, bytes32 filterId) = _createBatchParts(
            batchAction
        );

        vm.expectEmit(true, false, false, false);
        emit IBatchRequestOraclePool.BatchRequestActionAdded(_actionId(batchAction));
        testObject.addBatchActionByParts(requestIds, patchIds, schemaId, filterId);
    }

    function test_addBatchActionByParts_RevertsIf_RequestMissing() public {
        BatchRequestAction memory batchAction = _createBatchAction(2);
        (bytes32[] memory requestIds, bytes32[] memory patchIds, bytes32 schemaId, bytes32 filterId) = _createBatchParts(
            batchAction
        );
        requestIds[1] = keccak256("unknown request");

        vm.expectRevert(IRequestOraclePool.RequestNotFound.selector);
        testObject.addBatchActionByParts(requestIds, patchIds, schemaId, filterId);
    }

    function test_addBatchActionByParts_RevertsIf_PatchMissing() public {
        BatchRequestAction memory batchAction = _createBatchAction(2);
        batchAction.patches[0] = _realPatch(address(0xBEEF));
        (bytes32[] memory requestIds, bytes32[] memory patchIds, bytes32 schemaId, bytes32 filterId) = _createBatchParts(
            batchAction
        );
        patchIds[0] = keccak256("unknown patch");

        vm.expectRevert(IRequestOraclePool.PrivatePatchNotFound.selector);
        testObject.addBatchActionByParts(requestIds, patchIds, schemaId, filterId);
    }

    function test_addBatchActionByParts_RevertsIf_SchemaMissing() public {
        BatchRequestAction memory batchAction = _createBatchAction(2);
        (bytes32[] memory requestIds, bytes32[] memory patchIds, , bytes32 filterId) = _createBatchParts(batchAction);

        vm.expectRevert(IRequestOraclePool.ResponseSchemaNotFound.selector);
        testObject.addBatchActionByParts(requestIds, patchIds, keccak256("unknown schema"), filterId);
    }

    function test_addBatchActionByParts_RevertsIf_FilterMissing() public {
        BatchRequestAction memory batchAction = _createBatchAction(2);
        (bytes32[] memory requestIds, bytes32[] memory patchIds, bytes32 schemaId, ) = _createBatchParts(batchAction);

        vm.expectRevert(IRequestOraclePool.JqFilterNotFound.selector);
        testObject.addBatchActionByParts(requestIds, patchIds, schemaId, keccak256("unknown filter"));
    }

    function test_addBatchActionByParts_RevertsIf_EmptyBatch() public {
        vm.expectRevert(IBatchRequestOraclePool.BatchSizeOutOfRange.selector);
        testObject.addBatchActionByParts(new bytes32[](0), new bytes32[](0), keccak256("s"), keccak256("f"));
    }

    function test_addBatchActionByParts_RevertsIf_PatchCountMismatch() public {
        vm.expectRevert(IBatchRequestOraclePool.PatchCountMismatch.selector);
        testObject.addBatchActionByParts(new bytes32[](2), new bytes32[](1), keccak256("s"), keccak256("f"));
    }

    function test_addBatchActionByParts_RevertsIf_MoreThanEightSources() public {
        vm.expectRevert(IBatchRequestOraclePool.BatchSizeOutOfRange.selector);
        testObject.addBatchActionByParts(new bytes32[](9), new bytes32[](9), keccak256("s"), keccak256("f"));
    }

    function test_addBatchAction_AcceptsExactlyEightSources() public {
        BatchRequestAction memory batchAction = _createBatchAction(8);

        uint256 actionId = testObject.addBatchAction(batchAction);

        assertEq(testObject.getBatchAction(actionId), abi.encode(batchAction));
    }

    function test_addBatchAction_RevertsIf_EmptyBatch() public {
        BatchRequestAction memory batchAction = _createBatchAction(0);

        vm.expectRevert(IBatchRequestOraclePool.BatchSizeOutOfRange.selector);
        testObject.addBatchAction(batchAction);
    }

    function test_addBatchAction_RevertsIf_MoreThanEightSources() public {
        BatchRequestAction memory batchAction = _createBatchAction(9);

        vm.expectRevert(IBatchRequestOraclePool.BatchSizeOutOfRange.selector);
        testObject.addBatchAction(batchAction);
    }

    function test_addBatchAction_RevertsIf_PatchCountMismatch() public {
        BatchRequestAction memory batchAction = _createBatchAction(2);
        batchAction.patches = new HTTPPrivatePatch[](1);
        batchAction.patches[0] = emptyPatch;

        vm.expectRevert(IBatchRequestOraclePool.PatchCountMismatch.selector);
        testObject.addBatchAction(batchAction);
    }

    function test_getAction_isNotCutIntoBatchPool() public {
        // The single-request getAction selector must not resolve on the batch diamond.
        (bool success, ) = address(diamond).call(abi.encodeWithSelector(IRequestOraclePool.getAction.selector, 0));
        assertFalse(success);
    }

    function testFuzz_addBatchAction_roundTripsForAnyBatchSize(uint256 sourceCount, string memory filter) public {
        sourceCount = bound(sourceCount, 1, 8);
        vm.assume(bytes(filter).length > 0);
        BatchRequestAction memory batchAction = _createBatchAction(sourceCount);
        batchAction.jqFilter = filter;

        uint256 actionId = testObject.addBatchAction(batchAction);

        assertEq(actionId, _actionId(batchAction));
        assertEq(testObject.getBatchAction(actionId), abi.encode(batchAction));
    }

    function testFuzz_addBatchAction_roundTripsForFuzzedContents(
        string memory host,
        string memory path,
        bytes memory body,
        string memory schema,
        string memory filter
    ) public {
        vm.assume(bytes(host).length > 0);
        vm.assume(bytes(schema).length > 0);
        vm.assume(bytes(filter).length > 0);

        HTTPRequest[] memory requests = new HTTPRequest[](2);
        requests[0] = HTTPRequest(RequestMethod.Get, host, path, new RequestHeader[](0), new QueryParameter[](0), body);
        requests[1] = HTTPRequest(
            RequestMethod.Post,
            string.concat(host, ".mirror"),
            path,
            new RequestHeader[](0),
            new QueryParameter[](0),
            body
        );
        HTTPPrivatePatch[] memory patches = new HTTPPrivatePatch[](2);
        patches[0] = emptyPatch;
        patches[1] = emptyPatch;
        BatchRequestAction memory batchAction = BatchRequestAction(requests, patches, schema, filter);

        uint256 actionId = testObject.addBatchAction(batchAction);

        assertEq(actionId, _actionId(batchAction));
        assertEq(testObject.getBatchAction(actionId), abi.encode(batchAction));
    }

    HTTPPrivatePatch private emptyPatch =
        HTTPPrivatePatch("", new RequestHeaderPatch[](0), new QueryParameterPatch[](0), "", address(0));

    function _actionId(BatchRequestAction memory batchAction) private pure returns (uint256) {
        return uint256(keccak256(abi.encode(BATCH_ACTION_DOMAIN, batchAction)));
    }

    function _realPatch(address td) private pure returns (HTTPPrivatePatch memory) {
        RequestHeaderPatch[] memory headers = new RequestHeaderPatch[](1);
        headers[0] = RequestHeaderPatch("Authorization", bytes("secret"));
        return HTTPPrivatePatch("", headers, new QueryParameterPatch[](0), "", td);
    }

    function _createBatchParts(
        BatchRequestAction memory batchAction
    ) private returns (bytes32[] memory requestIds, bytes32[] memory patchIds, bytes32 schemaId, bytes32 filterId) {
        IRequestOraclePool parts = IRequestOraclePool(address(diamond));
        uint256 sourceCount = batchAction.requests.length;
        requestIds = new bytes32[](sourceCount);
        patchIds = new bytes32[](sourceCount);
        for (uint256 i = 0; i < sourceCount; ++i) {
            requestIds[i] = parts.addRequest(batchAction.requests[i]);
            patchIds[i] = parts.addPrivatePatch(batchAction.patches[i]);
        }
        schemaId = parts.addResponseSchema(batchAction.responseSchema);
        filterId = parts.addJqFilter(batchAction.jqFilter);
        return (requestIds, patchIds, schemaId, filterId);
    }

    function _createBatchAction(uint256 sourceCount) private view returns (BatchRequestAction memory batchAction) {
        HTTPRequest[] memory requests = new HTTPRequest[](sourceCount);
        HTTPPrivatePatch[] memory patches = new HTTPPrivatePatch[](sourceCount);
        for (uint256 i = 0; i < sourceCount; ++i) {
            requests[i] = HTTPRequest(
                RequestMethod.Get,
                string.concat("api", vm.toString(i), ".example.com"),
                "/price",
                new RequestHeader[](0),
                new QueryParameter[](0),
                ""
            );
            patches[i] = emptyPatch;
        }
        return BatchRequestAction(requests, patches, "uint256", "map(.price) | add");
    }
}
