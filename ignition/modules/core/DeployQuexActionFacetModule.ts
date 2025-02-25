import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeployQuexActionFacetModule = buildModule("DeployQuexActionFacetModule", (m) => {
    const facet = m.contract("QuexActionFacet");
    return { facet };
});

export default DeployQuexActionFacetModule;