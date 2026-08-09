import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "ethers";
import DeployBatchRequestOracleDiamondModule from "./DeployBatchRequestOracleDiamondModule";
import { BatchRequestActionFacet__factory } from "../../../../typechain";
import DeployBatchRequestActionFacetModule from "./DeployBatchRequestActionFacetModule";

const AddBatchRequestActionFacetToBatchRequestOracleModule = buildModule(
    "AddBatchRequestActionFacetToBatchRequestOracleModule",
    (m) => {
        const batchRequestsDiamond = m.useModule(DeployBatchRequestOracleDiamondModule).batchRequestsDiamond;
        const facet = m.useModule(DeployBatchRequestActionFacetModule).facet;
        const facetInterface = BatchRequestActionFacet__factory.createInterface();

        const facetCuts = [
            {
                target: facet,
                action: 0,
                selectors: [
                    facetInterface.getFunction("addAction").selector,
                    facetInterface.getFunction("addActionByParts").selector,
                    facetInterface.getFunction("addRequest").selector,
                    facetInterface.getFunction("addPrivatePatch").selector,
                    facetInterface.getFunction("addResponseSchema").selector,
                    facetInterface.getFunction("addJqFilter").selector,
                    facetInterface.getFunction("getAction").selector,
                    facetInterface.getFunction("addBatchAction").selector,
                    facetInterface.getFunction("addBatchActionByParts").selector,
                    facetInterface.getFunction("getBatchAction").selector,
                ]
            }
        ];

        m.call(batchRequestsDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);
        return { batchRequestsDiamond };
    }
);

export default AddBatchRequestActionFacetToBatchRequestOracleModule;
