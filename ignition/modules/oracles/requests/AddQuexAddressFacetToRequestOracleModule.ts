import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "ethers";
import DeployRequestOracleDiamondModule from "./DeployRequestOracleDiamondModule";
import { QuexAddressFacet__factory } from "../../../../typechain";
import DeployQuexAddressFacetModule from "../common/DeployQuexAddressFacetModule";

const AddQuexAddressFacetToRequestOracleModule = buildModule("AddQuexAddressFacetToRequestOracleModule", (m) => {
    const requestsDiamond = m.useModule(DeployRequestOracleDiamondModule).requestsDiamond;
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

    m.call(requestsDiamond, "diamondCut", [facetCuts, ethers.ZeroAddress, "0x"]);
    return { requestsDiamond };
});

export default AddQuexAddressFacetToRequestOracleModule;
