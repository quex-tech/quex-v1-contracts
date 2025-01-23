import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeployTrustDomainFacetModule = buildModule("DeployTrustDomainFacetModule", (m) => {
    const facet = m.contract("TrustDomainFacet");
    return { facet };
});

export default DeployTrustDomainFacetModule;