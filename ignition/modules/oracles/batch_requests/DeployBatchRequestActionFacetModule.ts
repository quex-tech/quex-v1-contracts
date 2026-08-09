import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeployBatchRequestActionFacetModule = buildModule("DeployBatchRequestActionFacetModule", (m) => {
    const facet = m.contract("BatchRequestActionFacet");

    return { facet };
});

export default DeployBatchRequestActionFacetModule;
