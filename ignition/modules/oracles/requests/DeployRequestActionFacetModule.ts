import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeployRequestActionFacetV2Module = buildModule("DeployRequestActionFacetV2Module", (m) => {
    const facet = m.contract("RequestActionFacetV2");

    return { facet };
});

export default DeployRequestActionFacetV2Module;