import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

//
// const FeedFacetModule = buildModule("FeedFacet", (m) => {
//     const facet = m.contract("FeedFacet");
//     const facetInterface = FeedFacet__factory.createInterface();
//
//     const facetCuts = [
//         {
//             target: facet,
//             action: 0,
//             selectors: [
//                 // feeds
//                 facetInterface.getFunction("addRequest").selector,
//                 facetInterface.getFunction("addPrivatePatch").selector,
//                 facetInterface.getFunction("addResponseSchema").selector,
//                 facetInterface.getFunction("addJqFilter").selector,
//                 facetInterface.getFunction("addFeed").selector,
//                 facetInterface.getFunction("getFeed").selector,
//
//                 // feed TD policy
//                 facetInterface.getFunction("allowTDForFeed").selector,
//                 facetInterface.getFunction("disallowTDForFeed").selector,
//                 facetInterface.getFunction("isTDAllowedForFeed").selector,
//
//                 // feed requests
//                 facetInterface.getFunction("processFeedResponse").selector,
//                 facetInterface.getFunction("sendFeedRequest").selector,
//                 facetInterface.getFunction("getFeedRequest").selector
//             ]
//         }
//     ];
//
//     return { facet, facetCuts, postCutTarget: ethers.ZeroAddress, postCutData: "0x" };
// });


const QuexDiamondModule = buildModule("QuexDiamond", (m) => {
    const quexDiamond = m.contract("QuexDiamond");

    return { quexDiamond };
});

export default QuexDiamondModule;