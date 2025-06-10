import env, { ethers, ignition } from "hardhat";
import * as fs from "fs";
import * as path from "path";
import {
    IConstantPriceMonetaryFacet__factory,
    IOraclePool__factory,
    IQuexAddressFacet__factory,
    IRequestOraclePool__factory,
    ITreasuryFacet__factory,
    QuexDiamond,
    QuexDiamond__factory,
    ITrustDomainRegistryExtended__factory,
    ITrustDomainPolicyFacet__factory
} from "../typechain";
import { AddressLike, Contract, EventLog, FunctionFragment } from "ethers";
import RequestOracleDeployAndConfigurationModule
    from "../ignition/modules/oracles/requests/RequestOracleDeployAndConfigurationModule";
import { quexConfig, QuexNetworkConfig, RequestOracleConfig } from "./quex_config";
import DeployQuexCoreDiamondModule from "../ignition/modules/core/DeployQuexCoreDiamondModule";
import { assert } from "console";

async function run(quexNetworkConfig: QuexNetworkConfig, tdQuoteData) {
    console.log("Start request oracle deploy");
    const { requestsDiamond } = await ignition.deploy(RequestOracleDeployAndConfigurationModule, { strategy: quexNetworkConfig.disableCreate2 ? "basic" : "create2" });

    const diamond = QuexDiamond__factory.connect(await requestsDiamond.getAddress(), requestsDiamond.runner);

    const { quexCoreDiamond } = await ignition.deploy(DeployQuexCoreDiamondModule);

    console.log("Validating interfaces");
    await validate_interfaces(diamond);
    console.log("Configure manager");
    await configure_manager(diamond, quexNetworkConfig.request);
    await set_config_values(diamond, quexNetworkConfig.request, await quexCoreDiamond.getAddress());
    console.log("Adding QE");
    await add_qe(quexCoreDiamond, diamond, tdQuoteData);
    console.log("Adding TD");
    await add_td(quexCoreDiamond, diamond, quexNetworkConfig.request, tdQuoteData);
    console.log("Done");
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
    const manager = "0xc8935964ff9a146a753e867ea3890f562b75604c6d6883305d776151177a5a74";
    await diamond.grantRole(manager, config.managerAddress);
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

async function add_qe(quexCoreDiamond: Contract, diamond: QuexDiamond, tdQuoteData) {

    const platformCaCert = {
        x: BigInt("24030003042588091771170974992323049441734798737906192722609658704857607787826"),
        y: BigInt("106254777459282516381561500528085635876136725707838022931959366032360701572062"),
        serial: BigInt("0x956f5dcdbd1be1e94049c9d4f433ce01570bde54"),
        notBefore: "0x3138303532313130353031305a",
        notAfter: "0x3333303532313130353031305a",
        extensions:
            "0x3081b8301f0603551d2304183016801422650cd65a9d3489f383b49552bf501b392706ac30520603551d1f044b30493047a045a043864168747470733a2f2f6365727469666963617465732e7472757374656473657276696365732e696e74656c2e636f6d2f496e74656c534758526f6f7443412e646572301d0603551d0e04160414956f5dcdbd1be1e94049c9d4f433ce01570bde54300e0603551d0f0101ff04040302010630120603551d130101ff040830060101ff020100",
        r: BigInt("42866170568685111900057008158509843856138296930751925740913709471306297805719"),
        s: BigInt("17237064055611587912602576747291700467597514190097038271137615530927947838334")
    };

    const processorPckCert = {
        x: BigInt("0x29d53fd6f1b968cd130b55911d8995f01c83ea869b4918fbbc756fa885989f48"),
        y: BigInt("0x7ad0885cfc54ff36f560053306f2b9d59c417e01ea23aee328db62e38460e8ec"),
        serial: BigInt("0x00cd53aca66dbd5e173beea15185ed20b13a099950"),
        notBefore: "0x3234313130343131323432345a",
        notAfter: "0x3331313130343131323432345a",
        extensions:
            "0x30820308301f0603551d23041830168014956f5dcdbd1be1e94049c9d4f433ce01570bde54306b0603551d1f046430623060a05ea05c865a68747470733a2f2f6170692e7472757374656473657276696365732e696e74656c2e636f6d2f7367782f63657274696669636174696f6e2f76342f70636b63726c3f63613d706c6174666f726d26656e636f64696e673d646572301d0603551d0e04160414e1699b3b1e544c5e36aa8feed189cc0eac22dbbd300e0603551d0f0101ff0404030206c0300c0603551d130101ff040230003082023906092a864886f84d010d010482022a30820226301e060a2a864886f84d010d010104103965e1a981cf369aa991217bc30ea60630820163060a2a864886f84d010d0102308201533010060b2a864886f84d010d0102010201023010060b2a864886f84d010d0102020201023010060b2a864886f84d010d0102030201023010060b2a864886f84d010d0102040201023010060b2a864886f84d010d0102050201033010060b2a864886f84d010d0102060201013010060b2a864886f84d010d0102070201003010060b2a864886f84d010d0102080201053010060b2a864886f84d010d0102090201003010060b2a864886f84d010d01020a0201003010060b2a864886f84d010d01020b0201003010060b2a864886f84d010d01020c0201003010060b2a864886f84d010d01020d0201003010060b2a864886f84d010d01020e0201003010060b2a864886f84d010d01020f0201003010060b2a864886f84d010d0102100201003010060b2a864886f84d010d01021102010b301f060b2a864886f84d010d0102120410020202020301000500000000000000003010060a2a864886f84d010d0103040200003014060a2a864886f84d010d01040406b0c06f000000300f060a2a864886f84d010d01050a0101301e060a2a864886f84d010d01060410f08e03bf85c728e0949340f6ea49f50d3044060a2a864886f84d010d010730363010060b2a864886f84d010d0107010101ff3010060b2a864886f84d010d0107020101ff3010060b2a864886f84d010d0107030101ff",
        authority: BigInt("0x956f5dcdbd1be1e94049c9d4f433ce01570bde54"),
        r: BigInt("0xc1fbdbd07acd76dc19598b56aa4ef9599dd8e06b036d7230940093ff3572f1aa"),
        s: BigInt("0xe2c0d05f02e43cd2e31efb19f7e615206c9dedca72a7e97639691f0d75254e16")
    };

    const qeReportData = tdQuoteData.qeReportData;

    const qeReportSignature = {
        r: BigInt(tdQuoteData.qeReportSignature.r),
        s: BigInt(tdQuoteData.qeReportSignature.s)
    };

    const tdRegistry = ITrustDomainRegistryExtended__factory.connect(await quexCoreDiamond.getAddress(), quexCoreDiamond.runner);
    await (await tdRegistry.addPlatformCAKey(
        platformCaCert.x,
        platformCaCert.y,
        platformCaCert.serial,
        platformCaCert.notBefore,
        platformCaCert.notAfter,
        platformCaCert.extensions,
        platformCaCert.r,
        platformCaCert.s
    )).wait();

    await (await tdRegistry.addPCK(
        processorPckCert.x,
        processorPckCert.y,
        processorPckCert.serial,
        processorPckCert.notBefore,
        processorPckCert.notAfter,
        processorPckCert.extensions,
        processorPckCert.authority,
        processorPckCert.r,
        processorPckCert.s
    )).wait();

    await (await tdRegistry.addQE(
        qeReportData,
        platformCaCert.serial,
        processorPckCert.serial,
        qeReportSignature.r,
        qeReportSignature.s
    )).wait();
}

async function add_td(quexCoreDiamond: Contract, diamond: QuexDiamond, config: RequestOracleConfig, tdQuoteData) {
    const attestationKey = {
        x: BigInt(tdQuoteData.attestationKey.x),
        y: BigInt(tdQuoteData.attestationKey.y)
    };
    const qeAuthenticationData = tdQuoteData.qeAuthenticationData;
    const quoteSignature = {
        r: BigInt(tdQuoteData.quoteSignature.r),
        s: BigInt(tdQuoteData.quoteSignature.s)
    };
    const tdQuote = tdQuoteData.tdQuote;
    const tdRegistry = ITrustDomainRegistryExtended__factory.connect(await quexCoreDiamond.getAddress(), quexCoreDiamond.runner);

    const tx = await tdRegistry.addTD(
        tdQuote,
        1,
        attestationKey.x,
        attestationKey.y,
        qeAuthenticationData,
        quoteSignature.r,
        quoteSignature.s
    );
    const txReceipt = await tx.wait();
    const tdId = (<EventLog>txReceipt?.logs[0]).args[0];
    console.log(`Registered TD with id: ${tdId}`);

    const tdPolicy = ITrustDomainPolicyFacet__factory.connect(await diamond.getAddress(), diamond.runner);
    await tdPolicy
        .connect(await ethers.getSigner(<string>config.managerAddress))
        .addToPool(tdId);
}

if (require.main === module) {
    const quexNetworkConfig: QuexNetworkConfig = quexConfig[env.network.name];
    const tdQuoteData = JSON.parse(fs.readFileSync(path.join(__dirname, "td_quotes/td_quote_parsed.json"), "utf8"));
    run(quexNetworkConfig, tdQuoteData).catch(console.error);
}

export { run };
