import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeployDepositManagerFacetModule = buildModule("DeployDepositManagerFacetModule", (m) => {
    const facet = m.contract("DepositManagerFacet");
    return { facet };
});

export default DeployDepositManagerFacetModule;