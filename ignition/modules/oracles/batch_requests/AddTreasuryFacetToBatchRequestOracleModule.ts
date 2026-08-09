import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "ethers";
import DeployBatchRequestOracleDiamondModule from "./DeployBatchRequestOracleDiamondModule";
import { TreasuryFacet__factory } from "../../../../typechain";
import DeployTreasuryFacetModule from "../common/DeployTreasuryFacetModule";

const AddTreasuryFacetToBatchRequestOracleModule = buildModule("AddTreasuryFacetToBatchRequestOracleModule", (m) => {
    const batchRequestsDiamond = m.useModule(DeployBatchRequestOracleDiamondModule).batchRequestsDiamond;
    const facet = m.useModule(DeployTreasuryFacetModule).facet;
    const facetInterface = TreasuryFacet__factory.createInterface();

    const facetCuts = [
        {
            target: facet,
            action: 0,
            selectors: [
                facetInterface.getFunction("getTreasury").selector,
                facetInterface.getFunction("setTreasury").selector,
            ]
        }
    ];

    m.call(batchRequestsDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);
    return { batchRequestsDiamond };
});

export default AddTreasuryFacetToBatchRequestOracleModule;
