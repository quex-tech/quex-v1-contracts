import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { FeedFacet__factory, P256VerifierFacet__factory, TrustDomainFacet__factory } from "../../typechain";
import { ethers } from "ethers";

const P256VerifierFacetModule = buildModule("P256VerifierFacet", (m) => {
    const facet = m.contract("P256VerifierFacet");
    const facetInterface = P256VerifierFacet__factory.createInterface();

    const facetCuts = [
        {
            target: facet,
            action: 0,
            selectors: [
                facetInterface.getFunction("ecdsa_verify").selector
            ]
        }
    ];

    return { facet, facetCuts, postCutTarget: ethers.ZeroAddress, postCutData: "0x" };
});

const TrustDomainFacetModule = buildModule("TrustDomainFacet", (m) => {
    const facet = m.contract("TrustDomainFacet");
    const facetInterface = TrustDomainFacet__factory.createInterface();

    const facetInitializer = m.contract("TrustDomainFacetInitializer");
    const initializerCallData = m.encodeFunctionCall(facetInitializer, "init", []);

    const facetCuts = [
        {
            target: facet,
            action: 0,
            selectors: [
                // add
                facetInterface.getFunction("addPlatformCAKey").selector,
                facetInterface.getFunction("addPCK").selector,
                facetInterface.getFunction("addQE").selector,
                facetInterface.getFunction("addTD").selector,

                // revoke
                facetInterface.getFunction("revokePlatformCA").selector,
                facetInterface.getFunction("revokePCK").selector,

                // get
                facetInterface.getFunction("getRootKey").selector,
                facetInterface.getFunction("getPlatformCAKey").selector,
                facetInterface.getFunction("getPCK").selector,
                facetInterface.getFunction("getQE").selector,
                facetInterface.getFunction("getTD").selector
            ]
        }
    ];

    return { facet, facetCuts, postCutTarget: facetInitializer, postCutData: initializerCallData };
});

const FeedFacetModule = buildModule("FeedFacet", (m) => {
    const facet = m.contract("FeedFacet");
    const facetInterface = FeedFacet__factory.createInterface();

    const facetCuts = [
        {
            target: facet,
            action: 0,
            selectors: [
                // feeds
                facetInterface.getFunction("addRequest").selector,
                facetInterface.getFunction("addPrivatePatch").selector,
                facetInterface.getFunction("addResponseSchema").selector,
                facetInterface.getFunction("addJqFilter").selector,
                facetInterface.getFunction("addFeed").selector,
                facetInterface.getFunction("getFeed").selector,

                // feed TD policy
                facetInterface.getFunction("allowTDForFeed").selector,
                facetInterface.getFunction("disallowTDForFeed").selector,
                facetInterface.getFunction("isTDAllowedForFeed").selector,

                // feed requests
                facetInterface.getFunction("processFeedResponse").selector,
                facetInterface.getFunction("sendFeedRequest").selector,
                facetInterface.getFunction("getFeedRequest").selector
            ]
        }
    ];

    return { facet, facetCuts, postCutTarget: ethers.ZeroAddress, postCutData: "0x" };
});


const QuexDiamondModule = buildModule("QuexDiamond", (m) => {
    const quexDiamond = m.contract("QuexDiamond");

    const p256VerifierFacet = m.useModule(P256VerifierFacetModule);
    m.call(quexDiamond, "diamondCut", [p256VerifierFacet.facetCuts, p256VerifierFacet.postCutTarget, p256VerifierFacet.postCutData], { "id": "P256VerifierFacet" });

    const trustDomainFacet = m.useModule(TrustDomainFacetModule);
    m.call(quexDiamond, "diamondCut", [trustDomainFacet.facetCuts, trustDomainFacet.postCutTarget, trustDomainFacet.postCutData], { "id": "TrustDomainFacet" });

    const feedFacet = m.useModule(FeedFacetModule);
    m.call(quexDiamond, "diamondCut", [feedFacet.facetCuts, feedFacet.postCutTarget, feedFacet.postCutData], { "id": "FeedFacet" });

    return { quexDiamond };
});

export default QuexDiamondModule;