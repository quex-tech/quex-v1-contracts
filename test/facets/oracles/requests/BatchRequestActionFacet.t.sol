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

    function setUp() public virtual {
        diamond = new QuexDiamond();
        diamond.init(address(this));
        BatchRequestActionFacet facet = new BatchRequestActionFacet();
        IERC2535DiamondCutInternal.FacetCut[] memory cuts = new IERC2535DiamondCutInternal.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](7);

        selectors[0] = BatchRequestActionFacet.addBatchAction.selector;
        selectors[1] = BatchRequestActionFacet.addBatchActionByParts.selector;
        selectors[2] = BatchRequestActionFacet.getBatchAction.selector;
        selectors[3] = RequestActionFacet.addRequest.selector;
        selectors[4] = RequestActionFacet.addPrivatePatch.selector;
        selectors[5] = RequestActionFacet.addResponseSchema.selector;
        selectors[6] = RequestActionFacet.addJqFilter.selector;

        cuts[0] = IERC2535DiamondCutInternal.FacetCut({
            target: address(facet),
            action: IERC2535DiamondCutInternal.FacetCutAction.ADD,
            selectors: selectors
        });

        diamond.diamondCut(cuts, address(0), "");
        testObject = IBatchRequestOraclePool(address(diamond));
    }

    function test_addBatchAction_emitsBatchRequestActionAddedEvent() public {
        (BatchRequestAction memory batchAction, uint256 actionId) = _createTwoSourceBatchAction();

        vm.expectEmit(true, false, false, true);
        emit IBatchRequestOraclePool.BatchRequestActionAdded(actionId);
        testObject.addBatchAction(batchAction);
    }

    function test_getBatchAction_returnsEncodedActionAfterAdd() public {
        (BatchRequestAction memory batchAction, uint256 actionId) = _createTwoSourceBatchAction();

        testObject.addBatchAction(batchAction);

        assertEq(testObject.getBatchAction(actionId), abi.encode(batchAction));
    }

    function test_addBatchActionByParts_emitsBatchRequestActionAddedEvent() public {
        (BatchRequestAction memory batchAction, uint256 actionId) = _createTwoSourceBatchAction();
        (bytes32[] memory requestIds, bytes32[] memory patchIds, bytes32 schemaId, bytes32 filterId) = _createBatchParts(
            batchAction
        );

        vm.expectEmit(true, false, false, true);
        emit IBatchRequestOraclePool.BatchRequestActionAdded(actionId);
        testObject.addBatchActionByParts(requestIds, patchIds, schemaId, filterId);
    }

    function test_addBatchActionByParts_RevertsIf_RequestMissing() public {
        (BatchRequestAction memory batchAction, ) = _createTwoSourceBatchAction();
        (bytes32[] memory requestIds, bytes32[] memory patchIds, bytes32 schemaId, bytes32 filterId) = _createBatchParts(
            batchAction
        );
        requestIds[1] = keccak256("unknown request");

        vm.expectRevert(IRequestOraclePool.RequestNotFound.selector);
        testObject.addBatchActionByParts(requestIds, patchIds, schemaId, filterId);
    }

    function test_addBatchActionByParts_RevertsIf_PatchMissing() public {
        (BatchRequestAction memory batchAction, ) = _createTwoSourceBatchAction();
        (bytes32[] memory requestIds, bytes32[] memory patchIds, bytes32 schemaId, bytes32 filterId) = _createBatchParts(
            batchAction
        );
        patchIds[0] = keccak256("unknown patch");

        vm.expectRevert(IRequestOraclePool.PrivatePatchNotFound.selector);
        testObject.addBatchActionByParts(requestIds, patchIds, schemaId, filterId);
    }

    function testFuzz_addBatchAction_roundTripsForAnyBatchSize(uint256 sourceCount, string memory filter) public {
        sourceCount = bound(sourceCount, 1, 8);
        vm.assume(bytes(filter).length > 0);
        BatchRequestAction memory batchAction = _createBatchAction(sourceCount);
        batchAction.jqFilter = filter;
        uint256 actionId = uint256(keccak256(abi.encode(batchAction)));

        vm.expectEmit(true, false, false, true);
        emit IBatchRequestOraclePool.BatchRequestActionAdded(actionId);
        testObject.addBatchAction(batchAction);

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

        vm.expectRevert(IBatchRequestOraclePool.BatchLengthMismatch.selector);
        testObject.addBatchAction(batchAction);
    }

    HTTPPrivatePatch private emptyPatch =
        HTTPPrivatePatch("", new RequestHeaderPatch[](0), new QueryParameterPatch[](0), "", address(0));

    function _createTwoSourceBatchAction()
        private
        view
        returns (BatchRequestAction memory batchAction, uint256 actionId)
    {
        HTTPRequest[] memory requests = new HTTPRequest[](2);
        requests[0] = HTTPRequest(
            RequestMethod.Get,
            "api.example.com",
            "/v1/price",
            new RequestHeader[](0),
            new QueryParameter[](0),
            ""
        );
        requests[1] = HTTPRequest(
            RequestMethod.Get,
            "api.other.org",
            "/price",
            new RequestHeader[](0),
            new QueryParameter[](0),
            ""
        );

        HTTPPrivatePatch[] memory patches = new HTTPPrivatePatch[](2);
        patches[0] = emptyPatch;
        patches[1] = emptyPatch;

        batchAction = BatchRequestAction(requests, patches, "uint256", "map(.price) | add");
        actionId = uint256(keccak256(abi.encode(batchAction)));
        return (batchAction, actionId);
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
