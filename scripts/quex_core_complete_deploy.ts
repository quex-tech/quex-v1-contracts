import {ignition} from "hardhat";
import {
    IFlowRegistry__factory,
    IP256Verifier__factory,
    IQuexActionRegistry__factory,
    IQuexMonetary__factory,
    ITrustDomainRegistry__factory,
    QuexDiamond,
    QuexDiamond__factory,
    IQuexMonetaryFacet__factory,
    IQuexActionFacet__factory,
    IDepositManager__factory,
    ITrustDomainRegistryExtended__factory
} from "../typechain";
import QuexCoreCompleteDeployAndConfigurationModule from "../ignition/modules/core/QuexCoreCompleteDeployAndConfigurationModule";
import {FunctionFragment} from "ethers";
import {ethers} from "hardhat";

import env from "hardhat";
import {quexConfig, QuexNetworkConfig, QuexCoreNetworkConfig, supportedSvns, SupportedSvns} from "./quex_config";

const pastTimeSkew = 15n * 60n; // 15 min
const futureTimeSkew = 30n; // 30 sec

export async function run(quexNetworkConfig: QuexNetworkConfig) {
    const {quexCoreDiamond} = await ignition.deploy(QuexCoreCompleteDeployAndConfigurationModule, {strategy: quexNetworkConfig.disableCreate2 ? "basic" : "create2"});

    const diamond = QuexDiamond__factory.connect(await quexCoreDiamond.getAddress(), quexCoreDiamond.runner);

    console.log("Validating interfaces");
    await validate_interfaces(diamond);
    console.log("Configure manager");
    await configure_manager(diamond, quexNetworkConfig.core);
    console.log("Setting config values");
    await set_config_values(diamond, quexNetworkConfig.core);
    console.log("Adding supported SVNS");
    await add_supported_svns(diamond, supportedSvns);
    console.log("Done");
}

async function validate_interfaces(diamond: QuexDiamond) {
    function validate_function(func: FunctionFragment) {
        if (selectors.includes(func.selector)) return;
        console.error(`Function ${func.name} (selector ${func.selector}) is not registered in QuexCore`);
    }

    const selectors = (await diamond.facets.staticCall()).reduce((acc: string[], v) => acc.concat(v.selectors), []);

    IFlowRegistry__factory.createInterface().forEachFunction((x) => validate_function(x));
    IP256Verifier__factory.createInterface().forEachFunction((x) => validate_function(x));
    IQuexActionRegistry__factory.createInterface().forEachFunction((x) => validate_function(x));
    IQuexMonetary__factory.createInterface().forEachFunction((x) => validate_function(x));
    ITrustDomainRegistry__factory.createInterface().forEachFunction((x) => validate_function(x));
    IDepositManager__factory.createInterface().forEachFunction((x) => validate_function(x));
}

async function configure_manager(diamond: QuexDiamond, config: QuexCoreNetworkConfig) {
    const manager = "0xc8935964ff9a146a753e867ea3890f562b75604c6d6883305d776151177a5a74";
    await (await diamond.grantRole(manager, config.managerAddress)).wait();
}

async function set_config_values(diamond: QuexDiamond, config: QuexCoreNetworkConfig) {
    const quexMonetary = IQuexMonetaryFacet__factory.connect(await diamond.getAddress(), diamond.runner);

    if ((await quexMonetary.getQuexFee(1)) != config.quexFee) {
        await quexMonetary
            .connect(await ethers.getSigner(<string>config.managerAddress))
            .setQuexFee(config.quexFee);
    }
    const quexFee = await quexMonetary.getQuexFee(1)
    console.log(`Quex fee: ${quexFee}`);

    if ((await quexMonetary.getTreasury()) != config.treasuryAddress) {
        await quexMonetary
            .connect(await ethers.getSigner(<string>config.managerAddress))
            .setTreasury(config.treasuryAddress);
    }
    const treasury = await quexMonetary.getTreasury();
    console.log(`Quex treasury: ${treasury}`);

    const quexActions = IQuexActionFacet__factory.connect(await diamond.getAddress(), diamond.runner);
    if (await quexActions.getQuexGas() != config.quexFulfillingGasCost) {
        await quexActions
            .connect(await ethers.getSigner(<string>config.managerAddress))
            .setQuexGas(config.quexFulfillingGasCost);
    }
    const quexGas = await quexActions.getQuexGas();
    console.log(`Quex gas: ${quexGas}`);

    let timeSkew = await quexActions.getTimeSkew();
    if (timeSkew[0] != pastTimeSkew || timeSkew[1] != futureTimeSkew) {
        const tx = await quexActions
            .connect(await ethers.getSigner(<string>config.managerAddress))
            .setTimeSkew(pastTimeSkew, futureTimeSkew);
    }
    timeSkew = await quexActions.getTimeSkew();
    console.log(`Time skew: ${timeSkew}`);
}

async function add_supported_svns(diamond: QuexDiamond, supportedSvns: SupportedSvns) {
    const tdRegistry = ITrustDomainRegistryExtended__factory.connect(await diamond.getAddress(), diamond.runner);
    for (const cpuSvn of supportedSvns.cpuSvnsToAdd) {
        await (await tdRegistry.allowCpuSvn(cpuSvn)).wait();
    }
    for (const teeTcbSvn of supportedSvns.teeTcbSvnsToAdd) {
        await (await tdRegistry.allowTeeTcbSvn(teeTcbSvn)).wait();
    }
    for (const cpuSvn of supportedSvns.cpuSvnsToRemove) {
        await (await tdRegistry.revokeCpuSvn(cpuSvn)).wait();
    }
    for (const teeTcbSvn of supportedSvns.teeTcbSvnsToRemove) {
        await (await tdRegistry.revokeTeeTcbSvn(teeTcbSvn)).wait();
    }
}

if (require.main === module) {
    const networkName = env.network.name;
    const hardhatConfig = require("hardhat").config;
    const quexNetworkConfig = quexConfig[networkName];
    console.log("Start Core deploy for network:", networkName);
    console.log(JSON.stringify(quexNetworkConfig, (_, v) => typeof v === "bigint" ? v.toString() : v, 2));
    console.log("Deployment salt:", hardhatConfig.ignition.strategyConfig.create2.salt);
    run(quexNetworkConfig).catch(console.error);
}
