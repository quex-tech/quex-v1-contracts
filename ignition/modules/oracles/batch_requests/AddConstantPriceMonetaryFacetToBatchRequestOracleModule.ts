import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "ethers";
import DeployBatchRequestOracleDiamondModule from "./DeployBatchRequestOracleDiamondModule";
import { ConstantPriceMonetaryFacet__factory } from "../../../../typechain";
import DeployConstantPriceMonetaryFacetModule from "../common/DeployConstantPriceMonetaryFacetModule";

const AddConstantPriceMonetaryFacetToBatchRequestOracleModule = buildModule(
    "AddConstantPriceMonetaryFacetToBatchRequestOracleModule",
    (m) => {
        const batchRequestsDiamond = m.useModule(DeployBatchRequestOracleDiamondModule).batchRequestsDiamond;
        const facet = m.useModule(DeployConstantPriceMonetaryFacetModule).facet;
        const facetInterface = ConstantPriceMonetaryFacet__factory.createInterface();

        const facetCuts = [
            {
                target: facet,
                action: 0,
                selectors: [
                    facetInterface.getFunction("getActionFee").selector,
                    facetInterface.getFunction("setActionFee").selector
                ]
            }
        ];

        m.call(batchRequestsDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);
        return { batchRequestsDiamond };
    }
);

export default AddConstantPriceMonetaryFacetToBatchRequestOracleModule;
