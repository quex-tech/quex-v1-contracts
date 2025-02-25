import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeployTreasuryFacetModule = buildModule("DeployTreasuryFacetModule", (m) => {
    const facet = m.contract("TreasuryFacet");

    return { facet };
});

export default DeployTreasuryFacetModule;