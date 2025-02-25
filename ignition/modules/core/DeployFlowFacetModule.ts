import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeployFlowFacetModule = buildModule("DeployFlowFacetModule", (m) => {
    const facet = m.contract("FlowFacet");

    return { facet };
});

export default DeployFlowFacetModule;