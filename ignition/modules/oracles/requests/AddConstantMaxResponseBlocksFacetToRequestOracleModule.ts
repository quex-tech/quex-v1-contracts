import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "ethers";
import DeployRequestOracleDiamondModule from "./DeployRequestOracleDiamondModule";
import { ConstantMaxResponseBlocksFacet__factory } from "../../../../typechain";
import DeployConstantMaxResponseBlocksFacetModule from "../common/DeployConstantMaxResponseBlocksFacetModule";

const AddConstantMaxResponseBlocksFacetToRequestOracleModule = buildModule("AddConstantMaxResponseBlocksFacetToRequestOracleModule", (m) => {
    const requestsDiamond = m.useModule(DeployRequestOracleDiamondModule).requestsDiamond;
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

    m.call(requestsDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);
    return { requestsDiamond };
});

export default AddConstantMaxResponseBlocksFacetToRequestOracleModule;
