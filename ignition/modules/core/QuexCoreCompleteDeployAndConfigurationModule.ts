import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import DeployQuexCoreDiamondModule from "./DeployQuexCoreDiamondModule";
import AddP256VerifierFacetToQuexCoreModule from "./AddP256VerifierFacetToQuexCoreModule";
import AddFlowFacetToQuexCoreModule from "./AddFlowFacetToQuexCoreModule";
import AddQuexMonetaryFacetToQuexCoreModule from "./AddQuexMonetaryFacetToQuexCoreModule";
import AddQuexActionFacetToQuexCoreModule from "./AddQuexActionFacetToQuexCoreModule";
import ConfigureTrustDomainModule from "./ConfigureTrustDomainModule";

const QuexCoreCompleteDeployAndConfigurationModule = buildModule("ValidateQuexCoreInterfacesModule", (m) => {
    const quexCoreDiamond = m.useModule(DeployQuexCoreDiamondModule).quexCoreDiamond;

    m.useModule(AddP256VerifierFacetToQuexCoreModule);
    m.useModule(ConfigureTrustDomainModule);
    m.useModule(AddFlowFacetToQuexCoreModule);
    m.useModule(AddQuexMonetaryFacetToQuexCoreModule);
    m.useModule(AddQuexActionFacetToQuexCoreModule);

    return { quexCoreDiamond };
});

export default QuexCoreCompleteDeployAndConfigurationModule;