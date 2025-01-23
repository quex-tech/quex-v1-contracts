import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeployRequestActionFacetModule = buildModule("DeployRequestActionFacetModule", (m) => {
    const facet = m.contract("RequestActionFacet");

    return { facet };
});

export default DeployRequestActionFacetModule;