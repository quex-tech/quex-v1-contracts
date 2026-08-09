import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import DeployBatchRequestOracleDiamondModule from "./DeployBatchRequestOracleDiamondModule";
import AddConstantPriceMonetaryFacetToBatchRequestOracleModule from "./AddConstantPriceMonetaryFacetToBatchRequestOracleModule";
import AddQuexAddressFacetToBatchRequestOracleModule from "./AddQuexAddressFacetToBatchRequestOracleModule";
import AddBatchRequestActionFacetToBatchRequestOracleModule from "./AddBatchRequestActionFacetToBatchRequestOracleModule";
import AddTreasuryFacetToBatchRequestOracleModule from "./AddTreasuryFacetToBatchRequestOracleModule";
import AddTrustDomainPolicyFacetToBatchRequestOracleModule from "./AddTrustDomainPolicyFacetToBatchRequestOracleModule";
import AddConstantMaxResponseBlocksFacetToBatchRequestOracleModule from "./AddConstantMaxResponseBlocksFacetToBatchRequestOracleModule";

const BatchRequestOracleDeployAndConfigurationModule = buildModule(
    "BatchRequestOracleDeployAndConfigurationModule",
    (m) => {
        const batchRequestsDiamond = m.useModule(DeployBatchRequestOracleDiamondModule).batchRequestsDiamond;

        m.useModule(AddConstantPriceMonetaryFacetToBatchRequestOracleModule);
        m.useModule(AddQuexAddressFacetToBatchRequestOracleModule);
        m.useModule(AddBatchRequestActionFacetToBatchRequestOracleModule);
        m.useModule(AddTreasuryFacetToBatchRequestOracleModule);
        m.useModule(AddTrustDomainPolicyFacetToBatchRequestOracleModule);
        m.useModule(AddConstantMaxResponseBlocksFacetToBatchRequestOracleModule);

        return { batchRequestsDiamond };
    }
);

export default BatchRequestOracleDeployAndConfigurationModule;
