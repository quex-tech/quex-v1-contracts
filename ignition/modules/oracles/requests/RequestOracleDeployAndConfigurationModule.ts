import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import DeployRequestOracleDiamondModule from "./DeployRequestOracleDiamondModule";
import AddConstantPriceMonetaryFacetToRequestOracleModule from "./AddConstantPriceMonetaryFacetToRequestOracleModule";
import AddQuexAddressFacetToRequestOracleModule from "./AddQuexAddressFacetToRequestOracleModule";
import AddRequestActionFacetV2ToRequestOracleModule from "./AddRequestActionFacetToRequestOracleModule";
import AddTreasuryFacetToRequestOracleModule from "./AddTreasuryFacetToRequestOracleModule";
import AddTrustDomainPolicyFacetToRequestOracleModule from "./AddTrustDomainPolicyFacetToRequestOracleModule";
import AddConstantMaxResponseBlocksFacetToRequestOracleModule from "./AddConstantMaxResponseBlocksFacetToRequestOracleModule";

const RequestOracleDeployAndConfigurationModule = buildModule("RequestOracleDeployAndConfigurationModule", (m) => {
    const requestsDiamond = m.useModule(DeployRequestOracleDiamondModule).requestsDiamond;

    m.useModule(AddConstantPriceMonetaryFacetToRequestOracleModule);
    m.useModule(AddQuexAddressFacetToRequestOracleModule);
    m.useModule(AddRequestActionFacetV2ToRequestOracleModule);
    m.useModule(AddTreasuryFacetToRequestOracleModule);
    m.useModule(AddTrustDomainPolicyFacetToRequestOracleModule);
    m.useModule(AddConstantMaxResponseBlocksFacetToRequestOracleModule);

    return { requestsDiamond };
});

export default RequestOracleDeployAndConfigurationModule;