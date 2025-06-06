import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeployConstantMaxResponseBlocksFacetModule = buildModule("DeployConstantMaxResponseBlocksFacetModule", (m) => {
    const facet = m.contract("ConstantMaxResponseBlocksFacet");

    return { facet };
});

export default DeployConstantMaxResponseBlocksFacetModule;