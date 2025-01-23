import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "ethers";
import DeployRequestOracleDiamondModule from "./DeployRequestOracleDiamondModule";
import { ConstantPriceMonetaryFacet__factory } from "../../../../typechain";
import DeployConstantPriceMonetaryFacetModule from "../common/DeployConstantPriceMonetaryFacetModule";

const AddConstantPriceMonetaryFacetToRequestOracleModule = buildModule("AddConstantPriceMonetaryFacetToRequestOracleModule", (m) => {
    const requestsDiamond = m.useModule(DeployRequestOracleDiamondModule).requestsDiamond;
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

    m.call(requestsDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);
    return { requestsDiamond };
});

export default AddConstantPriceMonetaryFacetToRequestOracleModule;
