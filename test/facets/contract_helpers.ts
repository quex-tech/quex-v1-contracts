import { ethers } from "hardhat";
import "@nomicfoundation/hardhat-ethers";
import {
    QuexDiamond,
    TrustDomainFacetInitializer__factory,
    TrustDomainFacet__factory,
    ITrustDomainRegistryExtended__factory,
    P256VerifierFacet__factory
} from "../../typechain";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { TDQuoteStruct } from "../../typechain/contracts/facets/trust_domain/TrustDomainFacet";
import { EventLog } from "ethers";

export namespace ContractHelpers {
    export namespace QuexRoles {
        export const Manager = "0xc8935964ff9a146a753e867ea3890f562b75604c6d6883305d776151177a5a74";
        export const ManagerAdmin = "0x022a473c59122cd9fd402a419eab4b7f67a55c9f8c5f6a76193742a43bc8db48";
    }

    export namespace P256VerifierFacet {
        export async function createAndAddToDiamond(diamond: QuexDiamond, deployer: HardhatEthersSigner) {
            const facet = await new P256VerifierFacet__factory(deployer).deploy();
            await facet.waitForDeployment();

            const facetCuts = [
                {
                    target: await facet.getAddress(),
                    action: 0,
                    selectors: [
                        facet.interface.getFunction("ecdsa_verify").selector,
                    ]
                }
            ];

            await (await diamond.diamondCut(facetCuts, ethers.ZeroAddress, "0x")).wait();
            return facet;
        }
    }

    export namespace TrustDomainFacet {
        export namespace TestData {
            export const rootCaKey = {
                x: BigInt("0x0ba9c4c0c0c86193a3fe23d6b02cda10a8bbd4e88e48b4458561a36e705525f5"),
                y: BigInt("0x67918e2edc88e40d860bd0cc4ee26aacc988e505a953558c453f6b0904ae7394"),
                notBefore: 1526899510,
                notAfter: 2524607999
            };

            export const platformCaCert = {
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

            export const processorPckCert = {
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

            export const qeReportData = {
                CPUSVN: "0x0202191b03ff00060000000000000000",
                MISCSELECT: "0x00000000",
                MRENCLAVE: "0xe5a3a7b5d830c2953b98534c6c59a3a34fdc34e933f7f5898f0a85cf08846bca",
                attributes: "0x1500000000000000e700000000000000",
                MRSIGNER: "0xdc9e2a7c6f948f17474e34a7fc43ed030f7c1563f1babddf6340c82e0e54a8c5",
                ISVProdID: "0x0200",
                ISVSVN: "0x0600",
                REPORT_DATA1: "0xb1031521f8c3d582214cf2ad732fabcebab018b821b5b69d838297bf0d2285a9",
                REPORT_DATA2: "0x0000000000000000000000000000000000000000000000000000000000000000"
            };

            export const qeReportSignature = {
                r: BigInt("0x5e301006050e5b32024d91d63d916bb90caa81edaee22df41e9de6dafba461f6"),
                s: BigInt("0x4a39eed0ccc11b5769704d9e8e0e4b702412f830e44a72e40033122a76a4aae7")
            };

            export const attestationKey = {
                x: BigInt("0xe677c409ec1f7632b791c907cdb2955c032b4972b971c005bb6711a2f7da7881"),
                y: BigInt("0x1590a686922b5a24191c92595806084b833b659e4aee627f82b60140a131372c")
            };
            export const qeAuthenticationData = "0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f";

            export const quoteSignature = {
                r: BigInt("0x22aea7554995bc5ea924ef84808ceebe88726056865564c572e5f6013487ed59"),
                s: BigInt("0xa83caf21fd8fd15841b54fff586f18f5cd2bbeff07cf669a9d423a6c3fe69bed")
            };

            export const tdQuote: TDQuoteStruct = {
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
                MROWNER:
                    "0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                MROWNERCONFIG:
                    "0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                RTMR0: "0x4ffa78653291b20268a4bef3302cd209358898f9d1ccf51b03683621768773223627d04c02a39a626bd2e2662cd969a2",
                RTMR1: "0x4cc938ae7cb4d7191f42f021ecda1789f6b18c780c5edd5b5ec82e537b61171eb0339600895992c8b16994369967d599",
                RTMR2: "0x6c3bebd263c8ec47d50e7c1506110e15bbce52b7e20ead7460cdb5dfe59115ebb20d387d795bbb9a2ce0fa5323290273",
                RTMR3: "0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                REPORT_DATA1: "0x292fa0aa29599c5369c7d63218a7989cdbe95b7cfd35bd4622fc558f70113255",
                REPORT_DATA2: "0x120ed3b57a3f76209c685a04351bf752b166aa8f9b827a97d42bf5df94e1d12b"
            };

            export const tdAddress = "0xCa614CD12D3b9515610C4d8b901De4b5641Be508";
            export const tdId = 1n;
        }

        export async function createAndAddToDiamond(diamond: QuexDiamond, deployer: HardhatEthersSigner) {
            const facet = await new TrustDomainFacet__factory(deployer).deploy();
            await facet.waitForDeployment();

            const trustDomainFacetInitializer = await new TrustDomainFacetInitializer__factory(deployer).deploy();
            await trustDomainFacetInitializer.waitForDeployment();
            const calldata = trustDomainFacetInitializer.interface.encodeFunctionData("init");

            const facetCuts = [
                {
                    target: await facet.getAddress(),
                    action: 0,
                    selectors: [
                        // add
                        facet.interface.getFunction("addPlatformCAKey").selector,
                        facet.interface.getFunction("addPCK").selector,
                        facet.interface.getFunction("addQE").selector,
                        facet.interface.getFunction("addTD").selector,

                        // revoke
                        facet.interface.getFunction("revokePlatformCA").selector,
                        facet.interface.getFunction("revokePCK").selector,
                        facet.interface.getFunction("revokeQE").selector,
                        facet.interface.getFunction("revokeTD").selector,

                        // get
                        facet.interface.getFunction("getRootKey").selector,
                        facet.interface.getFunction("getPlatformCAKey").selector,
                        facet.interface.getFunction("getPCK").selector,
                        facet.interface.getFunction("getQE").selector,
                        facet.interface.getFunction("getTD").selector,
                        facet.interface.getFunction("isTDValid").selector,
                        facet.interface.getFunction("getTDSignerAddress").selector,
                        facet.interface.getFunction("getQEId").selector,
                        facet.interface.getFunction("getQEAuthority").selector,

                        // CPU_SVN and TEE_TCB_SVN
                        facet.interface.getFunction("allowTeeTcbSvn").selector,
                        facet.interface.getFunction("allowCpuSvn").selector,
                        facet.interface.getFunction("revokeTeeTcbSvn").selector,
                        facet.interface.getFunction("revokeCpuSvn").selector,
                        facet.interface.getFunction("isTeeTcbSvnAllowed").selector,
                        facet.interface.getFunction("isCpuSvnAllowed").selector,

                        // get counters
                        facet.interface.getFunction("getPCKCounterByPlatformCA").selector,
                        facet.interface.getFunction("getQECounterByProcessorPCK").selector,
                        facet.interface.getFunction("getTDCounterByQE").selector,
                        facet.interface.getFunction("getTeeTcbSvnTDCounter").selector,
                        facet.interface.getFunction("getCpuSvnQECounter").selector,
                    ]
                }
            ];

            await (await diamond.diamondCut(facetCuts, await trustDomainFacetInitializer.getAddress(), calldata)).wait();
            return facet;
        }

        export async function addPlatformKey(diamond: QuexDiamond) {
            const tdRegistry = ITrustDomainRegistryExtended__factory.connect(await diamond.getAddress(), diamond.runner);
            const platformCaCert = TestData.platformCaCert;
            await tdRegistry.addPlatformCAKey(
                platformCaCert.x,
                platformCaCert.y,
                platformCaCert.serial,
                platformCaCert.notBefore,
                platformCaCert.notAfter,
                platformCaCert.extensions,
                platformCaCert.r,
                platformCaCert.s);
        }

        export async function addPCK(diamond: QuexDiamond, processorPckCert: any = undefined) {
            const tdRegistry = ITrustDomainRegistryExtended__factory.connect(await diamond.getAddress(), diamond.runner);
            processorPckCert ||= TestData.processorPckCert;
            await tdRegistry
                .addPCK(
                    processorPckCert.x,
                    processorPckCert.y,
                    processorPckCert.serial,
                    processorPckCert.notBefore,
                    processorPckCert.notAfter,
                    processorPckCert.extensions,
                    processorPckCert.authority,
                    processorPckCert.r,
                    processorPckCert.s
                );
        }

        export async function allowTeeTcbSvn(diamond: QuexDiamond) {
            const tdRegistry = ITrustDomainRegistryExtended__factory.connect(await diamond.getAddress(), diamond.runner);
            await tdRegistry.allowTeeTcbSvn(TestData.tdQuote.TEE_TCB_SVN);
        }

        export async function allowCpuSvn(diamond: QuexDiamond) {
            const tdRegistry = ITrustDomainRegistryExtended__factory.connect(await diamond.getAddress(), diamond.runner);
            await tdRegistry.allowCpuSvn(TestData.qeReportData.CPUSVN);
        }

        export async function revokeTeeTcbSvn(diamond: QuexDiamond) {
            const tdRegistry = ITrustDomainRegistryExtended__factory.connect(await diamond.getAddress(), diamond.runner);
            await tdRegistry.revokeTeeTcbSvn(TestData.tdQuote.TEE_TCB_SVN);
        }

        export async function revokeCpuSvn(diamond: QuexDiamond) {
            const tdRegistry = ITrustDomainRegistryExtended__factory.connect(await diamond.getAddress(), diamond.runner);
            await tdRegistry.revokeCpuSvn(TestData.qeReportData.CPUSVN);
        }

        export async function addQE(diamond: QuexDiamond) {
            await allowCpuSvn(diamond);
            const tdRegistry = ITrustDomainRegistryExtended__factory.connect(await diamond.getAddress(), diamond.runner);
            const tx = await tdRegistry
                .addQE(
                    TestData.qeReportData,
                    TestData.platformCaCert.serial,
                    TestData.processorPckCert.serial,
                    TestData.qeReportSignature.r,
                    TestData.qeReportSignature.s
                );
            const txReceipt = await tx.wait();
            return (<EventLog>txReceipt?.logs[0]).args[0];
        }

        export async function addTD(diamond: QuexDiamond) {
            await allowTeeTcbSvn(diamond);
            const tdRegistry = ITrustDomainRegistryExtended__factory.connect(await diamond.getAddress(), diamond.runner);
            const tx = await tdRegistry
                .addTD(
                    TestData.tdQuote,
                    1,
                    TestData.attestationKey.x,
                    TestData.attestationKey.y,
                    TestData.qeAuthenticationData,
                    TestData.quoteSignature.r,
                    TestData.quoteSignature.s
                );
            const txReceipt = await tx.wait();
            return (<EventLog>txReceipt?.logs[0]).args[0];
        }

        export async function configureFully(diamond: QuexDiamond) {
            await addPlatformKey(diamond);
            await addPCK(diamond);
            await addQE(diamond);
            await addTD(diamond);
        }
    }
}