import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "ethers";
import DeployRequestOracleDiamondModule from "./DeployRequestOracleDiamondModule";
import { TrustDomainPolicyFacet__factory } from "../../../../typechain";
import DeployTrustDomainPolicyFacetModule from "../common/DeployTrustDomainPolicyFacetModule";

const AddTrustDomainPolicyFacetToRequestOracleModule = buildModule("AddTrustDomainPolicyFacetToRequestOracleModule", (m) => {
    const requestsDiamond = m.useModule(DeployRequestOracleDiamondModule).requestsDiamond;
    const facet = m.useModule(DeployTrustDomainPolicyFacetModule).facet;
    const facetInterface = TrustDomainPolicyFacet__factory.createInterface();

    const facetCuts = [
        {
            target: facet,
            action: 0,
            selectors: [
                facetInterface.getFunction("isInPool").selector,
                facetInterface.getFunction("addToPool").selector,
                facetInterface.getFunction("removeFromPool").selector
            ]
        }
    ];

    m.call(requestsDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);
    return { requestsDiamond };
});

export default AddTrustDomainPolicyFacetToRequestOracleModule;
