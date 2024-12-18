import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import QuexDiamondModule from "./QuexDiamond";
import FeedFacetConfiguration from "./FeedFacetConfiguration";

const feed = {
    "request": {
        "method": 0,
        "host": "www.binance.com",
        "path": "/api/v3/depth",
        "headers": [],
        "parameters": [{ "key": "symbol", "value": "BTCUSDT" }, { "key": "limit", "value": "5" }],
        "body": "0x"
    },
    "patch": {
        "pathSuffix": "0x",
        "headers": [],
        "parameters": [],
        "body": "0x"
    },
    "schema": "(uint256,(uint256,uint256)[5],(uint256,uint256)[5])",
    "filter": "[.lastUpdateId]+([.bids,.asks]|map(map(map(tonumber*100000000|floor))))"
};


export default buildModule("FeedFacetTestConfiguration", (m) => {
    const quexDiamond = m.useModule(QuexDiamondModule).quexDiamond;
    const feedWrap = m.contractAt("FeedFacet", quexDiamond);

    const tdAddress = m.useModule(FeedFacetConfiguration).tdAddress;

    // create feed
    const addRequest = m.call(feedWrap, "addRequest", [feed.request]);
    const requestId = m.readEventArgument(addRequest, "RequestAdded", "requestId");

    const addPrivatePatch = m.call(feedWrap, "addPrivatePatch", [tdAddress, feed.patch]);
    const patchId = m.readEventArgument(addPrivatePatch, "PrivatePatchAdded", "patchId");

    const addJqFilter = m.call(feedWrap, "addJqFilter", [feed.filter]);
    const filterId = m.readEventArgument(addJqFilter, "JqFilterAdded", "filterId");

    const addResponseSchema = m.call(feedWrap, "addResponseSchema", [feed.schema]);
    const schemaId = m.readEventArgument(addResponseSchema, "ResultSchemaAdded", "schemaId");

    const addFeed = m.call(feedWrap, "addFeed", [requestId, patchId, schemaId, filterId]);
    const feedId = m.readEventArgument(addFeed, "FeedAdded", "feedId");

    // deploy callback contract
    const callbackContract = m.contract("OnChainFeedRequestTestContract", [quexDiamond, feedId]);

    return  {callbackContract};
});