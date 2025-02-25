import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { QuexMonetaryFacet__factory } from "../../../typechain";
import { ethers } from "ethers";
import QuexDiamondModule from "../QuexDiamond";

const QuexMonetaryFacetModule = buildModule("QuexMonetaryFacet", (m) => {
    const facet = m.contract("QuexMonetaryFacet");
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

    const quexDiamond = m.useModule(QuexDiamondModule).quexDiamond;
    m.call(quexDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);

    const quexMonetaryFacet = m.contractAt("QuexMonetaryFacet", quexDiamond, {id: "QuexCore_QuexMonetaryFacet"});

    return { quexMonetaryFacet };
});

export default QuexMonetaryFacetModule;