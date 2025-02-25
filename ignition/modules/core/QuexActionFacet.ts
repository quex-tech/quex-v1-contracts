import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { QuexActionFacet__factory } from "../../../typechain";
import { ethers } from "ethers";
import QuexDiamondModule from "../QuexDiamond";

const QuexActionFacetModule = buildModule("QuexActionFacet", (m) => {
    const facet = m.contract("QuexActionFacet");
    const facetInterface = QuexActionFacet__factory.createInterface();

    const facetCuts = [
        {
            target: facet,
            action: 0,
            selectors: [
                // requests
                facetInterface.getFunction("createRequest").selector,
                facetInterface.getFunction("fulfillRequest").selector,
                facetInterface.getFunction("getRequestFee").selector,
                facetInterface.getFunction("getQuexGas").selector,
                facetInterface.getFunction("setQuexGas").selector,

                // push
                facetInterface.getFunction("pushData").selector
            ]
        }
    ];

    const quexDiamond = m.useModule(QuexDiamondModule).quexDiamond;
    m.call(quexDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);

    const quexActionFacet = m.contractAt("QuexActionFacet", quexDiamond, {id: "QuexCore_QuexActionFacet"});

    return { quexActionFacet };
});

export default QuexActionFacetModule;