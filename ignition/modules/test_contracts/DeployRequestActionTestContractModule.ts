import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import QuexCoreCompleteDeployAndConfigurationModule from "../core/QuexCoreCompleteDeployAndConfigurationModule";
import RequestOracleDeployAndConfigurationModule from "../oracles/requests/RequestOracleDeployAndConfigurationModule";

const DeployRequestActionTestContractModule = buildModule("DeployRequestActionTestContractModule", (m) => {
    const { quexCoreDiamond } = m.useModule(QuexCoreCompleteDeployAndConfigurationModule);
    const { requestsDiamond } = m.useModule(RequestOracleDeployAndConfigurationModule);
    const requestActionTestContract = m.contract("RequestActionTestContract", [quexCoreDiamond, requestsDiamond]);

    return { requestActionTestContract };
});

export default DeployRequestActionTestContractModule;