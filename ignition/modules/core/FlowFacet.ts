import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { FlowFacet__factory } from "../../../typechain";
import { ethers } from "ethers";
import QuexDiamondModule from "../QuexDiamond";

const FlowFacetModule = buildModule("FlowFacet", (m) => {
    const facet = m.contract("FlowFacet");
    const facetInterface = FlowFacet__factory.createInterface();

    const facetCuts = [
        {
            target: facet,
            action: 0,
            selectors: [
                facetInterface.getFunction("createFlow").selector,
                facetInterface.getFunction("getFlow").selector,
            ]
        }
    ];

    const quexDiamond = m.useModule(QuexDiamondModule).quexDiamond;
    m.call(quexDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);

    const flowFacet = m.contractAt("FlowFacet", quexDiamond, {id: "QuexCore_FlowFacet"});

    return { flowFacet };
});

export default FlowFacetModule;