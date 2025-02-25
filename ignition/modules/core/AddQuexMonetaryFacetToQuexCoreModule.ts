import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import DeployQuexCoreDiamondModule from "./DeployQuexCoreDiamondModule";
import { QuexMonetaryFacet__factory } from "../../../typechain";
import { ethers } from "ethers";
import DeployQuexMonetaryFacetModule from "./DeployQuexMonetaryFacetModule";

const AddQuexMonetaryFacetToQuexCoreModule = buildModule("AddQuexMonetaryFacetToQuexCoreModule", (m) => {
    const quexCoreDiamond = m.useModule(DeployQuexCoreDiamondModule).quexCoreDiamond;
    const facet = m.useModule(DeployQuexMonetaryFacetModule).facet;
    const facetInterface = QuexMonetaryFacet__factory.createInterface();

    const facetCuts = [
        {
            target: facet,
            action: 0,
            selectors: [
                // quex fee
                facetInterface.getFunction("getQuexFee").selector,
                facetInterface.getFunction("setQuexFee").selector,

                // treasury
                facetInterface.getFunction("getTreasury").selector,
                facetInterface.getFunction("setTreasury").selector
            ]
        }
    ];

    m.call(quexCoreDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);
    return { quexCoreDiamond };
});

export default AddQuexMonetaryFacetToQuexCoreModule;