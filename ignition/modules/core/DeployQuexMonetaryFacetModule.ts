import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeployQuexMonetaryFacetModule = buildModule("DeployQuexMonetaryFacetModule", (m) => {
    const facet = m.contract("QuexMonetaryFacet");
    return { facet };
});

export default DeployQuexMonetaryFacetModule;