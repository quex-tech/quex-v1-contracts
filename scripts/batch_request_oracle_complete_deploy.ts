import env, {ethers, ignition} from "hardhat";
import {
    IBatchRequestOraclePool__factory,
    IConstantMaxResponseBlocksFacet__factory,
    IConstantPriceMonetaryFacet__factory,
    IOraclePool__factory,
    IQuexAddressFacet__factory,
    IRequestOraclePool__factory,
    ITreasuryFacet__factory,
    QuexDiamond,
    QuexDiamond__factory
} from "../typechain";
import {AddressLike, FunctionFragment} from "ethers";
import BatchRequestOracleDeployAndConfigurationModule
    from "../ignition/modules/oracles/batch_requests/BatchRequestOracleDeployAndConfigurationModule";
import {quexConfig, QuexNetworkConfig, RequestOracleConfig} from "./quex_config";
import DeployQuexCoreDiamondModule from "../ignition/modules/core/DeployQuexCoreDiamondModule";
import assert from "node:assert/strict";

// Part primitives reused from RequestActionFacet that the batch pool exposes. The single-request
// addAction / addActionByParts / getAction are intentionally NOT cut, so they are not validated here.
const REQUEST_PART_SELECTORS = ["addRequest", "addPrivatePatch", "addResponseSchema", "addJqFilter"] as const;

async function run(quexNetworkConfig: QuexNetworkConfig) {
    console.log("Start batch request oracle deploy");
    const {batchRequestsDiamond} = await ignition.deploy(BatchRequestOracleDeployAndConfigurationModule, {strategy: quexNetworkConfig.disableCreate2 ? "basic" : "create2"});

    const diamond = QuexDiamond__factory.connect(await batchRequestsDiamond.getAddress(), batchRequestsDiamond.runner);

    const {quexCoreDiamond} = await ignition.deploy(DeployQuexCoreDiamondModule);

    console.log("Validating interfaces");
    await validate_interfaces(diamond);
    console.log("Configure manager");
    await configure_manager(diamond, quexNetworkConfig.request);
    await set_config_values(diamond, quexNetworkConfig.request, await quexCoreDiamond.getAddress());
    console.log("Done");
}

async function validate_interfaces(diamond: QuexDiamond) {
    const missing: string[] = [];

    function require_selector(name: string, selector: string) {
        if (!selectors.includes(selector)) {
            missing.push(name);
        }
    }

    function require_function(func: FunctionFragment) {
        require_selector(func.name, func.selector);
    }

    const selectors = (await diamond.facets.staticCall()).reduce((acc: string[], v) => acc.concat(v.selectors), []);

    // A batch pool resolves action content via getBatchAction, not the single-request getAction, so
    // getAction is deliberately not cut and must be excluded from the IOraclePool completeness check.
    const oraclePoolInterface = IOraclePool__factory.createInterface();
    const omittedSelectors = new Set<string>([oraclePoolInterface.getFunction("getAction").selector]);
    oraclePoolInterface.forEachFunction((x) => {
        if (!omittedSelectors.has(x.selector)) require_function(x);
    });
    IBatchRequestOraclePool__factory.createInterface().forEachFunction((x) => require_function(x));

    const requestInterface = IRequestOraclePool__factory.createInterface();
    for (const name of REQUEST_PART_SELECTORS) {
        require_selector(name, requestInterface.getFunction(name).selector);
    }

    if (missing.length > 0) {
        throw new Error(`Batch oracle pool is missing selectors for: ${missing.join(", ")}`);
    }
}

async function configure_manager(diamond: QuexDiamond, config: RequestOracleConfig) {
    const managerRoleId = "0xc8935964ff9a146a753e867ea3890f562b75604c6d6883305d776151177a5a74";
    const hasRole = await diamond.hasRole(managerRoleId, config.managerAddress);
    if (!hasRole) {
        await diamond.grantRole(managerRoleId, config.managerAddress);
    }
}

async function set_config_values(diamond: QuexDiamond, config: RequestOracleConfig, quexCoreAddress: AddressLike) {
    const manager = await ethers.getSigner(<string>config.managerAddress);

    const constantPriceMonetaryFacet = IConstantPriceMonetaryFacet__factory.connect(
        await diamond.getAddress(),
        diamond.runner
    );
    if ((await constantPriceMonetaryFacet.getActionFee(0)) != config.actionFee) {
        await constantPriceMonetaryFacet.connect(manager).setActionFee(config.actionFee);
    }
    assert.equal(await constantPriceMonetaryFacet.getActionFee(0), config.actionFee);

    const maxResponseBlocksFacet = IConstantMaxResponseBlocksFacet__factory.connect(
        await diamond.getAddress(),
        diamond.runner
    );
    if ((await maxResponseBlocksFacet.getMaxResponseBlocks(0)) != config.maxResponseBlocks) {
        await maxResponseBlocksFacet.connect(manager).setMaxResponseBlocks(config.maxResponseBlocks);
    }
    assert.equal(await maxResponseBlocksFacet.getMaxResponseBlocks(0), config.maxResponseBlocks);

    const treasuryFacet = ITreasuryFacet__factory.connect(await diamond.getAddress(), diamond.runner);
    if ((await treasuryFacet.getTreasury()) != config.treasuryAddress) {
        await treasuryFacet.connect(manager).setTreasury(config.treasuryAddress);
    }
    assert.equal(await treasuryFacet.getTreasury(), config.treasuryAddress);

    const quexAddressFacet = IQuexAddressFacet__factory.connect(await diamond.getAddress(), diamond.runner);
    if ((await quexAddressFacet.getQuexAddress()) != quexCoreAddress) {
        await quexAddressFacet.connect(manager).setQuexAddress(quexCoreAddress);
    }
    assert.equal(await quexAddressFacet.getQuexAddress(), quexCoreAddress);
}

if (require.main === module) {
    const quexNetworkConfig: QuexNetworkConfig = quexConfig[env.network.name];
    run(quexNetworkConfig).catch((error) => {
        console.error(error);
        process.exitCode = 1;
    });
}

export {run};
