import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import DeployRequestOracleDiamondModule from "./DeployRequestOracleDiamondModule";
import AddConstantPriceMonetaryFacetToRequestOracleModule from "./AddConstantPriceMonetaryFacetToRequestOracleModule";
import AddQuexAddressFacetToRequestOracleModule from "./AddQuexAddressFacetToRequestOracleModule";
import AddRequestActionFacetToRequestOracleModule from "./AddRequestActionFacetToRequestOracleModule";
import AddTreasuryFacetToRequestOracleModule from "./AddTreasuryFacetToRequestOracleModule";
import AddTrustDomainPolicyFacetToRequestOracleModule from "./AddTrustDomainPolicyFacetToRequestOracleModule";

const RequestOracleDeployAndConfigurationModule = buildModule("RequestOracleDeployAndConfigurationModule", (m) => {
    const requestsDiamond = m.useModule(DeployRequestOracleDiamondModule).requestsDiamond;

    m.useModule(AddConstantPriceMonetaryFacetToRequestOracleModule);
    m.useModule(AddQuexAddressFacetToRequestOracleModule);
    m.useModule(AddRequestActionFacetToRequestOracleModule);
    m.useModule(AddTreasuryFacetToRequestOracleModule);
    m.useModule(AddTrustDomainPolicyFacetToRequestOracleModule);

    return { requestsDiamond };
});

export default RequestOracleDeployAndConfigurationModule;