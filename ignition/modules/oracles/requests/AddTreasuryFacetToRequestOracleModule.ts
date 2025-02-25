import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "ethers";
import DeployRequestOracleDiamondModule from "./DeployRequestOracleDiamondModule";
import { TreasuryFacet__factory } from "../../../../typechain";
import DeployTreasuryFacetModule from "../common/DeployTreasuryFacetModule";

const AddTreasuryFacetToRequestOracleModule = buildModule("AddTreasuryFacetToRequestOracleModule", (m) => {
    const requestsDiamond = m.useModule(DeployRequestOracleDiamondModule).requestsDiamond;
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

    m.call(requestsDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);
    return { requestsDiamond };
});

export default AddTreasuryFacetToRequestOracleModule;
