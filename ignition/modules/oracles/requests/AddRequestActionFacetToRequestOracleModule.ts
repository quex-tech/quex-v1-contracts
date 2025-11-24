import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "ethers";
import DeployRequestOracleDiamondModule from "./DeployRequestOracleDiamondModule";
import { RequestActionFacet__factory } from "../../../../typechain";
import DeployRequestActionFacetV2Module from "./DeployRequestActionFacetModule";

const AddRequestActionFacetV2ToRequestOracleModule = buildModule("AddRequestActionFacetV2ToRequestOracleModule", (m) => {
    const requestsDiamond = m.useModule(DeployRequestOracleDiamondModule).requestsDiamond;
    const facet = m.useModule(DeployRequestActionFacetV2Module).facet;
    const facetInterface = RequestActionFacet__factory.createInterface();

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
                facetInterface.getFunction("addPrivatePatchConsumer").selector,
                facetInterface.getFunction("removePrivatePatchConsumer").selector,
                facetInterface.getFunction("hasAccessToPrivatePatch").selector,
            ]
        }
    ];

    m.call(requestsDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);
    return { requestsDiamond };
});

export default AddRequestActionFacetV2ToRequestOracleModule;
