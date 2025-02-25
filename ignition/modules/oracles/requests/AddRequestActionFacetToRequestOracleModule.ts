import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "ethers";
import DeployRequestOracleDiamondModule from "./DeployRequestOracleDiamondModule";
import { RequestActionFacet__factory } from "../../../../typechain";
import DeployRequestActionFacetModule from "./DeployRequestActionFacetModule";

const AddRequestActionFacetToRequestOracleModule = buildModule("AddRequestActionFacetToRequestOracleModule", (m) => {
    const requestsDiamond = m.useModule(DeployRequestOracleDiamondModule).requestsDiamond;
    const facet = m.useModule(DeployRequestActionFacetModule).facet;
    const facetInterface = RequestActionFacet__factory.createInterface();

    const facetCuts = [
        {
            target: facet,
            action: 0,
            selectors: [
                facetInterface.getFunction("addFlow").selector,
                facetInterface.getFunction("addRequest").selector,
                facetInterface.getFunction("addPrivatePatch").selector,
                facetInterface.getFunction("addResponseSchema").selector,
                facetInterface.getFunction("addJqFilter").selector,
                facetInterface.getFunction("createRequest").selector,
                facetInterface.getFunction("getAction").selector,
                facetInterface.getFunction("getActionTD").selector,
            ]
        }
    ];

    m.call(requestsDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);
    return { requestsDiamond };
});

export default AddRequestActionFacetToRequestOracleModule;
