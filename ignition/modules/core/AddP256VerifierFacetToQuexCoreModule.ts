import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import DeployQuexCoreDiamondModule from "./DeployQuexCoreDiamondModule";
import { P256VerifierFacet__factory } from "../../../typechain";
import { ethers } from "ethers";
import DeployP256VerifierFacetModule from "./DeployP256VerifierFacetModule";

const AddP256VerifierFacetToQuexCoreModule = buildModule("AddP256VerifierFacetToQuexCoreModule", (m) => {
    const quexCoreDiamond = m.useModule(DeployQuexCoreDiamondModule).quexCoreDiamond;
    const facet = m.useModule(DeployP256VerifierFacetModule).facet;
    const facetInterface = P256VerifierFacet__factory.createInterface();

    const facetCuts = [{
        target: facet,
        action: 0,
        selectors: [
            facetInterface.getFunction("ecdsaVerify").selector
        ]
    }];

    m.call(quexCoreDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);
    return { quexCoreDiamond };
});

export default AddP256VerifierFacetToQuexCoreModule;