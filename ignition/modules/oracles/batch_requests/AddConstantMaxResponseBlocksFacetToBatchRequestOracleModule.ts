import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "ethers";
import DeployBatchRequestOracleDiamondModule from "./DeployBatchRequestOracleDiamondModule";
import { ConstantMaxResponseBlocksFacet__factory } from "../../../../typechain";
import DeployConstantMaxResponseBlocksFacetModule from "../common/DeployConstantMaxResponseBlocksFacetModule";

const AddConstantMaxResponseBlocksFacetToBatchRequestOracleModule = buildModule(
    "AddConstantMaxResponseBlocksFacetToBatchRequestOracleModule",
    (m) => {
        const batchRequestsDiamond = m.useModule(DeployBatchRequestOracleDiamondModule).batchRequestsDiamond;
        const facet = m.useModule(DeployConstantMaxResponseBlocksFacetModule).facet;
        const facetInterface = ConstantMaxResponseBlocksFacet__factory.createInterface();

        const facetCuts = [
            {
                target: facet,
                action: 0,
                selectors: [
                    facetInterface.getFunction("getMaxResponseBlocks").selector,
                    facetInterface.getFunction("setMaxResponseBlocks").selector
                ]
            }
        ];

        m.call(batchRequestsDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);
        return { batchRequestsDiamond };
    }
);

export default AddConstantMaxResponseBlocksFacetToBatchRequestOracleModule;
