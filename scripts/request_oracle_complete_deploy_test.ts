import env, { ethers, ignition } from "hardhat";
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

async function run() {
    const quexNetworkConfig: QuexNetworkConfig = quexConfig[env.network.name];

    const { requestsDiamond } = await ignition.deploy(RequestOracleDeployAndConfigurationModule, { strategy: quexNetworkConfig.disableCreate2 ? "basic" : "create2" });

    const diamond = QuexDiamond__factory.connect(await requestsDiamond.getAddress(), requestsDiamond.runner);

    const { quexCoreDiamond } = await ignition.deploy(DeployQuexCoreDiamondModule);

    await validate_interfaces(diamond);
    await configure_manager(diamond, quexNetworkConfig.request);
    await set_config_values(diamond, quexNetworkConfig.request, await quexCoreDiamond.getAddress());
    await add_qe(quexCoreDiamond, diamond);
    await add_td(quexCoreDiamond, diamond, quexNetworkConfig.request);
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
    await (await diamond.grantRole(manager, config.managerAddress)).wait();
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

async function add_qe(quexCoreDiamond: Contract, diamond: QuexDiamond) {
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

    const qeReportData = {
        CPUSVN: "0x0202191b03ff00060000000000000000",
        MISCSELECT: "0x00000000",
        MRENCLAVE: "0xb7ae9ab69e76f7794a56b0db1915281d435d488c91d406ed33a7939caf8730f8",
        attributes: "0x1500000000000000e700000000000000",
        MRSIGNER: "0xdc9e2a7c6f948f17474e34a7fc43ed030f7c1563f1babddf6340c82e0e54a8c5",
        ISVProdID: "0x0200",
        ISVSVN: "0x0700",
        REPORT_DATA1: "0xd0d0f33108c8d0b3a1fd12b89cbb2da83008fa7cf6bb8790bb1fce84bab50883",
        REPORT_DATA2: "0x0000000000000000000000000000000000000000000000000000000000000000"
    };

    const qeReportSignature = {
        r: BigInt("0x7147cf25ee58424d74253a83a5fae1640d4b8205e25f771e58625745135fc7df"),
        s: BigInt("0x641d51dafa5f09813ade394de15b45cf9d4c28a22bb27833298a8366b7777d0a")
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

async function add_td(quexCoreDiamond: Contract, diamond: QuexDiamond, config: RequestOracleConfig) {
    const attestationKey = {
        x: BigInt("0xe5fd6c7662d01c628a462c8c788935592dce033aee1784545b5de995faed2cd6"),
        y: BigInt("0x44d6886df0ad8aef9c8dcfce65e9b8fabd087df2cdb9211e4f0a0dcae23fdcb3")
    };
    const qeAuthenticationData = "0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f";

    const quoteSignature = {
        r: BigInt("0xdf6bb445b3b1de857a80227057b58dcd17e0c4c0ae2d61128a72168ce3b53a43"),
        s: BigInt("0x305f942ad1d8f001ef94161553c5a127030193c8340a387bb3dc194ebf0a7f0c")
    };

    const tdQuote = {
        USER_DATA: "0x9e7915cba6b92a808258e5db174b6f2d00000000",
        TEE_TCB_SVN: "0x05010200000000000000000000000000",
        MRSEAM: "0x1cc6a17ab799e9a693fac7536be61c12ee1e0fabada82d0c999e08ccee2aa86de77b0870f558c570e7ffe55d6d47fa04",
        MRSIGNERSEAM:
            "0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        SEAMATTRIBUTES: "0x0000000000000000",
        TDATTRIBUTES: "0x0000001000000000",
        XFAM: "0xe702060000000000",
        MRTD: "0x91eb2b44d141d4ece09f0c75c2c53d247a3c68edd7fafe8a3520c942a604a407de03ae6dc5f87f27428b2538873118b7",
        MRCONFIGID:
            "0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        MROWNER: "0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        MROWNERCONFIG:
            "0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        RTMR0: "0x3e9ad874e1991fc4aabb42bf82384cccfa2e08308ea19164825cf650b7432c74c58db1842a69ce903cbc1a513692084a",
        RTMR1: "0xf88085916dc4020a4820236baa57013a7aee6fc05fff338334146c67576a17bd5cc5ce85ad909283adc835007f20ad5e",
        RTMR2: "0x831c3811fdb222d3db5752917da9f719636d6fac356da5ddae597d7a4af7a7f1d5b7bc40688c382088c8e1c7e3e511df",
        RTMR3: "0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        REPORT_DATA1: "0xb23974e9267308bd821c34038e00072bf1e297f308227d98de387deb50f9ca2e",
        REPORT_DATA2: "0xbed328af1471f291e53eff602130f5ab79d006ee040553016775d79261362770"
    };

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
    console.log(tdId);

    const tdPolicy = ITrustDomainPolicyFacet__factory.connect(await diamond.getAddress(), diamond.runner);
    await tdPolicy
        .connect(await ethers.getSigner(<string>config.managerAddress))
        .addToPool(tdId);
}

run().catch(console.error);
