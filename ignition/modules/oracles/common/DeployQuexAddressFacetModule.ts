import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeployQuexAddressFacetModule = buildModule("DeployQuexAddressFacetModule", (m) => {
    const facet = m.contract("QuexAddressFacet");

    return { facet };
});

export default DeployQuexAddressFacetModule;