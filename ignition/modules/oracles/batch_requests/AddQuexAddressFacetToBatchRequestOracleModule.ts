import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "ethers";
import DeployBatchRequestOracleDiamondModule from "./DeployBatchRequestOracleDiamondModule";
import { QuexAddressFacet__factory } from "../../../../typechain";
import DeployQuexAddressFacetModule from "../common/DeployQuexAddressFacetModule";

const AddQuexAddressFacetToBatchRequestOracleModule = buildModule(
    "AddQuexAddressFacetToBatchRequestOracleModule",
    (m) => {
        const batchRequestsDiamond = m.useModule(DeployBatchRequestOracleDiamondModule).batchRequestsDiamond;
        const facet = m.useModule(DeployQuexAddressFacetModule).facet;
        const facetInterface = QuexAddressFacet__factory.createInterface();

        const facetCuts = [
            {
                target: facet,
                action: 0,
                selectors: [
                    facetInterface.getFunction("getQuexAddress").selector,
                    facetInterface.getFunction("setQuexAddress").selector,
                ]
            }
        ];

        m.call(batchRequestsDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);
        return { batchRequestsDiamond };
    }
);

export default AddQuexAddressFacetToBatchRequestOracleModule;
