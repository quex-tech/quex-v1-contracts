// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import "solady/src/utils/Base64.sol";
import "forge-std/StdJson.sol";
import "../../contracts/interfaces/oracles/IBatchRequestOraclePool.sol";

contract BatchActionEncodingTest is Test {
    using stdJson for string;

    function test_batchActionEncoding() public view {
        string memory path = "test/testdata/test-vectors/batch_action_test_vectors.json";
        string memory json = vm.readFile(path);

        BatchRequestAction memory batchAction = _canonicalVectorAction();
        bytes memory encoded = abi.encode(batchAction);

        bytes memory expectedEncoded = Base64.decode(json.readString(".vectors[0].bytes"));
        assertEq(encoded, expectedEncoded, "Encoded bytes do not match expected test vector");

        bytes32 expectedActionId = json.readBytes32(".vectors[0].action_id");
        assertEq(keccak256(encoded), expectedActionId, "Action id does not match expected test vector");
    }

    function _canonicalVectorAction() private pure returns (BatchRequestAction memory batchAction) {
        HTTPRequest[] memory requests = new HTTPRequest[](2);
        QueryParameter[] memory firstParameters = new QueryParameter[](1);
        firstParameters[0] = QueryParameter("symbol", "BTCUSDT");
        requests[0] = HTTPRequest(
            RequestMethod.Get,
            "api.binance.com",
            "/api/v3/ticker/price",
            new RequestHeader[](0),
            firstParameters,
            ""
        );
        RequestHeader[] memory secondHeaders = new RequestHeader[](1);
        secondHeaders[0] = RequestHeader("Accept", "application/json");
        requests[1] = HTTPRequest(
            RequestMethod.Get,
            "api.coinbase.com",
            "/v2/prices/BTC-USD/spot",
            secondHeaders,
            new QueryParameter[](0),
            ""
        );

        HTTPPrivatePatch[] memory patches = new HTTPPrivatePatch[](2);
        patches[0] = HTTPPrivatePatch("", new RequestHeaderPatch[](0), new QueryParameterPatch[](0), "", address(0));
        patches[1] = HTTPPrivatePatch("", new RequestHeaderPatch[](0), new QueryParameterPatch[](0), "", address(0));

        return BatchRequestAction(requests, patches, "uint256", "map(.price | tonumber) | add");
    }
}
