import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeployConstantPriceMonetaryFacetModule = buildModule("DeployConstantPriceMonetaryFacetModule", (m) => {
    const facet = m.contract("ConstantPriceMonetaryFacet");

    return { facet };
});

export default DeployConstantPriceMonetaryFacetModule;