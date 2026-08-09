import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "ethers";
import DeployBatchRequestOracleDiamondModule from "./DeployBatchRequestOracleDiamondModule";
import { TrustDomainPolicyFacet__factory } from "../../../../typechain";
import DeployTrustDomainPolicyFacetModule from "../common/DeployTrustDomainPolicyFacetModule";

const AddTrustDomainPolicyFacetToBatchRequestOracleModule = buildModule(
    "AddTrustDomainPolicyFacetToBatchRequestOracleModule",
    (m) => {
        const batchRequestsDiamond = m.useModule(DeployBatchRequestOracleDiamondModule).batchRequestsDiamond;
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

        m.call(batchRequestsDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);
        return { batchRequestsDiamond };
    }
);

export default AddTrustDomainPolicyFacetToBatchRequestOracleModule;
