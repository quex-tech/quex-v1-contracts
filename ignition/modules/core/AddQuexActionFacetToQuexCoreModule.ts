import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import DeployQuexCoreDiamondModule from "./DeployQuexCoreDiamondModule";
import { QuexActionFacet__factory } from "../../../typechain";
import { ethers } from "ethers";
import DeployQuexActionFacetModule from "./DeployQuexActionFacetModule";

const AddQuexActionFacetToQuexCoreModule = buildModule("AddQuexActionFacetToQuexCoreModule", (m) => {
    const quexCoreDiamond = m.useModule(DeployQuexCoreDiamondModule).quexCoreDiamond;
    const facet = m.useModule(DeployQuexActionFacetModule).facet;
    const facetInterface = QuexActionFacet__factory.createInterface();

    const facetCuts = [
        {
            target: facet,
            action: 0,
            selectors: [
                // common
                facetInterface.getFunction("setTimeSkew").selector,
                facetInterface.getFunction("getTimeSkew").selector,

                // requests
                facetInterface.getFunction("createRequest").selector,
                facetInterface.getFunction("fulfillRequest").selector,
                facetInterface.getFunction("getRequestFee").selector,
                facetInterface.getFunction("getQuexGas").selector,
                facetInterface.getFunction("setQuexGas").selector,
                facetInterface.getFunction("getRequest").selector,

                // push
                facetInterface.getFunction("pushData").selector
            ]
        }
    ];

    m.call(quexCoreDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);
    return { quexCoreDiamond };
});

export default AddQuexActionFacetToQuexCoreModule;