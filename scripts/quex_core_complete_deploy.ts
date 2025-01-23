import { ignition } from "hardhat";
import {
    IFlowRegistry__factory,
    IP256Verifier__factory,
    IQuexActionRegistry__factory,
    IQuexMonetary__factory,
    ITrustDomainRegistry__factory,
    QuexDiamond,
    QuexDiamond__factory
} from "../typechain";
import QuexCoreCompleteDeployAndConfigurationModule
    from "../ignition/modules/core/QuexCoreCompleteDeployAndConfigurationModule";
import { FunctionFragment } from "ethers";

async function run() {
    const { quexCoreDiamond } = await ignition.deploy(QuexCoreCompleteDeployAndConfigurationModule);

    const diamond = QuexDiamond__factory.connect(await quexCoreDiamond.getAddress(), quexCoreDiamond.runner);

    await validate_interfaces(diamond);

    // todo: set quex fee
}

async function validate_interfaces(diamond: QuexDiamond) {
    function validate_function(func: FunctionFragment) {
        if (selectors.includes(func.selector))
            return;
        console.error(`Function ${func.name} (selector ${func.selector}) is not registered in QuexCore`);
    }

    const selectors = (await diamond.facets.staticCall())
        .reduce((acc: string[], v) => acc.concat(v.selectors), []);

    IFlowRegistry__factory.createInterface().forEachFunction(x => validate_function(x));
    IP256Verifier__factory.createInterface().forEachFunction(x => validate_function(x));
    IQuexActionRegistry__factory.createInterface().forEachFunction(x => validate_function(x));
    IQuexMonetary__factory.createInterface().forEachFunction(x => validate_function(x));
    ITrustDomainRegistry__factory.createInterface().forEachFunction(x => validate_function(x));
}

run().catch(console.error);