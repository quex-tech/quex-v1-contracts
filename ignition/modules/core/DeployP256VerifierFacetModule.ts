import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeployP256VerifierFacetModule = buildModule("DeployP256VerifierFacetModule", (m) => {
    const facet = m.contract("P256VerifierFacet");

    return { facet };
});

export default DeployP256VerifierFacetModule;