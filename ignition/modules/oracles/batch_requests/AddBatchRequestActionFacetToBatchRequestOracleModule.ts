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

        // Only the content-addressed part primitives are cut in from the inherited RequestActionFacet;
        // the single-request addAction / addActionByParts / getAction are intentionally omitted so a
        // batch pool cannot silently serve or resolve v1 actions.
        const facetCuts = [
            {
                target: facet,
                action: 0,
                selectors: [
                    facetInterface.getFunction("addRequest").selector,
                    facetInterface.getFunction("addPrivatePatch").selector,
                    facetInterface.getFunction("addResponseSchema").selector,
                    facetInterface.getFunction("addJqFilter").selector,
                    facetInterface.getFunction("addBatchAction").selector,
                    facetInterface.getFunction("addBatchActionByParts").selector,
                    facetInterface.getFunction("getBatchAction").selector,
                    facetInterface.getFunction("maxBatchSize").selector,
                ]
            }
        ];

        m.call(batchRequestsDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);
        return { batchRequestsDiamond };
    }
);

export default AddBatchRequestActionFacetToBatchRequestOracleModule;
