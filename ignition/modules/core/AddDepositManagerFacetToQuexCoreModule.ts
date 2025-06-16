import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import DeployQuexCoreDiamondModule from "./DeployQuexCoreDiamondModule";
import { DepositManagerFacet__factory } from "../../../typechain";
import { ethers } from "ethers";
import DeployDepositManagerFacetModule from "./DeployDepositManagerFacetModule";

const AddDepositManagerFacetToQuexCoreModule = buildModule("AddDepositManagerFacetToQuexCoreModule", (m) => {
    const quexCoreDiamond = m.useModule(DeployQuexCoreDiamondModule).quexCoreDiamond;
    const facet = m.useModule(DeployDepositManagerFacetModule).facet;
    const facetInterface = DepositManagerFacet__factory.createInterface();

    const facetCuts = [
        {
            target: facet,
            action: 0,
            selectors: [
                facetInterface.getFunction("createSubscription").selector,
                facetInterface.getFunction("setOwner").selector,
                facetInterface.getFunction("deposit").selector,
                facetInterface.getFunction("withdraw").selector,
                facetInterface.getFunction("addConsumer").selector,
                facetInterface.getFunction("removeConsumer").selector,
                facetInterface.getFunction("balance").selector,
                facetInterface.getFunction("withdrawableBalance").selector,

                // internal
                facetInterface.getFunction("hasAccessToSubscription").selector,
                facetInterface.getFunction("reserve").selector,
                facetInterface.getFunction("release").selector,
                facetInterface.getFunction("fulfill").selector
            ]
        }
    ];

    m.call(quexCoreDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);
    return { quexCoreDiamond };
});

export default AddDepositManagerFacetToQuexCoreModule;