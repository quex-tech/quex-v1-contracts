// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import "@solidstate/contracts/interfaces/IERC2535DiamondCutInternal.sol";
import {QuexDiamond} from "../../../../contracts/diamond/QuexDiamond.sol";
import {BatchRequestActionFacet} from "../../../../contracts/facets/oracles/requests/BatchRequestActionFacet.sol";
import "../../../../contracts/interfaces/oracles/IBatchRequestOraclePool.sol";

contract BatchRequestActionFacetTest is Test {
    QuexDiamond internal diamond;
    IBatchRequestOraclePool internal testObject;

    function setUp() public virtual {
        diamond = new QuexDiamond();
        diamond.init(address(this));
        BatchRequestActionFacet facet = new BatchRequestActionFacet();
        IERC2535DiamondCutInternal.FacetCut[] memory cuts = new IERC2535DiamondCutInternal.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](3);

        selectors[0] = BatchRequestActionFacet.addBatchAction.selector;
        selectors[1] = BatchRequestActionFacet.addBatchActionByParts.selector;
        selectors[2] = BatchRequestActionFacet.getBatchAction.selector;

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
}
