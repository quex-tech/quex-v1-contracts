import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import DeployQuexCoreDiamondModule from "./DeployQuexCoreDiamondModule";
import { FlowFacet__factory } from "../../../typechain";
import { ethers } from "ethers";
import DeployFlowFacetModule from "./DeployFlowFacetModule";

const AddFlowFacetToQuexCoreModule = buildModule("AddFlowFacetToQuexCoreModule", (m) => {
    const quexCoreDiamond = m.useModule(DeployQuexCoreDiamondModule).quexCoreDiamond;
    const facet = m.useModule(DeployFlowFacetModule).facet;
    const facetInterface = FlowFacet__factory.createInterface();

    const facetCuts = [
        {
            target: facet,
            action: 0,
            selectors: [
                facetInterface.getFunction("createFlow").selector,
                facetInterface.getFunction("getFlow").selector
            ]
        }
    ];

    m.call(quexCoreDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);
    return { quexCoreDiamond };
});

export default AddFlowFacetToQuexCoreModule;