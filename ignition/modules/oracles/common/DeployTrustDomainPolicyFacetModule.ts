import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeployTrustDomainPolicyFacetModule = buildModule("DeployTrustDomainPolicyFacetModule", (m) => {
    const facet = m.contract("TrustDomainPolicyFacet");

    return { facet };
});

export default DeployTrustDomainPolicyFacetModule;