import env, {ethers, ignition} from "hardhat";
import {
    IConstantPriceMonetaryFacet__factory,
    IOraclePool__factory,
    IQuexAddressFacet__factory,
    IRequestOraclePool__factory,
    ITreasuryFacet__factory,
    QuexDiamond,
    QuexDiamond__factory
} from "../typechain";
import {AddressLike, FunctionFragment} from "ethers";
import RequestOracleDeployAndConfigurationModule
    from "../ignition/modules/oracles/requests/RequestOracleDeployAndConfigurationModule";
import {quexConfig, QuexNetworkConfig, RequestOracleConfig} from "./quex_config";
import DeployQuexCoreDiamondModule from "../ignition/modules/core/DeployQuexCoreDiamondModule";
import {getQuexCoreAddress} from "./common";
import {assert} from "console";

// IGNITION_DEPLOYMENT_ID (e.g. chain-42161-batch) deploys an extra pool beside the
// chain's default one; set IGNITION_SALT to a fresh value with it, or create2 resolves
// to the already deployed default pool. The extra pool binds to the chain's existing
// QuexCore instead of deploying a second core under the new salt.
async function run(quexNetworkConfig: QuexNetworkConfig) {
    console.log("Start request oracle deploy");
    const deploymentId = process.env.IGNITION_DEPLOYMENT_ID;
    const {requestsDiamond} = await ignition.deploy(RequestOracleDeployAndConfigurationModule, {
        strategy: quexNetworkConfig.disableCreate2 ? "basic" : "create2",
        deploymentId,
    });

    const diamond = QuexDiamond__factory.connect(await requestsDiamond.getAddress(), requestsDiamond.runner);

    let quexCoreAddress: string;
    if (deploymentId) {
        quexCoreAddress = await getQuexCoreAddress();
    } else {
        const {quexCoreDiamond} = await ignition.deploy(DeployQuexCoreDiamondModule);
        quexCoreAddress = await quexCoreDiamond.getAddress();
    }

    console.log("Validating interfaces");
    await validate_interfaces(diamond);
    console.log("Configure manager");
    await configure_manager(diamond, quexNetworkConfig.request);
    await set_config_values(diamond, quexNetworkConfig.request, quexCoreAddress);
    console.log(`Done: request oracle ${await diamond.getAddress()} -> core ${quexCoreAddress}`);
}

async function validate_interfaces(diamond: QuexDiamond) {
    function validate_function(func: FunctionFragment) {
        if (selectors.includes(func.selector)) return;
        console.error(`Function ${func.name} (selector ${func.selector}) is not registered in oracle`);
    }

    const selectors = (await diamond.facets.staticCall()).reduce((acc: string[], v) => acc.concat(v.selectors), []);

    IOraclePool__factory.createInterface().forEachFunction((x) => validate_function(x));
    IRequestOraclePool__factory.createInterface().forEachFunction((x) => validate_function(x));
}

async function configure_manager(diamond: QuexDiamond, config: RequestOracleConfig) {
    const managerRoleId = "0xc8935964ff9a146a753e867ea3890f562b75604c6d6883305d776151177a5a74";
    const hasRole = await diamond.hasRole(managerRoleId, config.managerAddress);
    if (!hasRole) {
        await diamond.grantRole(managerRoleId, config.managerAddress);
    }
}

async function set_config_values(diamond: QuexDiamond, config: RequestOracleConfig, quexCoreAddress: AddressLike) {
    const constantPriceMonetaryFacet = IConstantPriceMonetaryFacet__factory.connect(
        await diamond.getAddress(),
        diamond.runner
    );
    if ((await constantPriceMonetaryFacet.getActionFee(0)) != config.actionFee) {
        await constantPriceMonetaryFacet
            .connect(await ethers.getSigner(<string>config.managerAddress))
            .setActionFee(config.actionFee);
    }
    assert((await constantPriceMonetaryFacet.getActionFee(0)) == config.actionFee);

    const treasuryFacet = ITreasuryFacet__factory.connect(await diamond.getAddress(), diamond.runner);
    if ((await treasuryFacet.getTreasury()) != config.treasuryAddress) {
        await treasuryFacet
            .connect(await ethers.getSigner(<string>config.managerAddress))
            .setTreasury(config.treasuryAddress);
    }
    assert((await treasuryFacet.getTreasury()) == config.treasuryAddress);

    const quexAddressFacet = IQuexAddressFacet__factory.connect(await diamond.getAddress(), diamond.runner);
    if ((await quexAddressFacet.getQuexAddress()) != quexCoreAddress) {
        await quexAddressFacet
            .connect(await ethers.getSigner(<string>config.managerAddress))
            .setQuexAddress(quexCoreAddress);
    }
    assert((await quexAddressFacet.getQuexAddress()) == quexCoreAddress);
}

if (require.main === module) {
    const quexNetworkConfig: QuexNetworkConfig = quexConfig[env.network.name];
    run(quexNetworkConfig).catch(console.error);
}

export {run};
