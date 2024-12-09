import { ethers } from "hardhat";
import "@nomicfoundation/hardhat-ethers";
import {
    P256Verifier,
    V1FeedRegistry,
    V1FeedRegistryPolicy,
    V1RequestLogic,
    V1RequestRegistry,
    V1TrustDomainRegistry,
    QuexDiamond,
    TrustDomainFacetInitializer__factory,
    P256Verifier__factory,
    TrustDomainFacet__factory,
    FeedFacet__factory,
    ITrustDomainRegistryExtended__factory
} from "../../typechain";
import {
    FeedStruct,
    FeedStructOutput,
    HTTPPrivatePatchStruct,
    HTTPRequestStruct
} from "../../typechain/interfaces/IV1FeedRegistry";
import { ContractTransactionResponse } from "ethers";
import { TDQuoteStruct } from "../../typechain/interfaces/IV1QuoteVerifier";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

export namespace ContractHelpers {
    export async function getOwner() { // todo: remove
        return (await ethers.getSigners())[0];
    }

    export async function getTransactionGasFee(txHash: string) {
        const txReceipt = await ethers.provider.getTransactionReceipt(txHash);
        if (txReceipt == null)
            return BigInt(0);
        return txReceipt.gasUsed * txReceipt.gasPrice;
    }

    export namespace TrustDomainFacet {
        export namespace TestData {
            export const rootCaKey = {
                x: BigInt("0x0ba9c4c0c0c86193a3fe23d6b02cda10a8bbd4e88e48b4458561a36e705525f5"),
                y: BigInt("0x67918e2edc88e40d860bd0cc4ee26aacc988e505a953558c453f6b0904ae7394"),
                notBefore: "0x3138303532313130343531305a",
                notAfter: "0x3439313233313233353935395a"
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
        }

        export async function createAndAddToDiamond(diamond: QuexDiamond, deployer: HardhatEthersSigner) {
            const p256Verifier = await new P256Verifier__factory(deployer).deploy();
            await p256Verifier.waitForDeployment();

            const facet = await new TrustDomainFacet__factory(deployer).deploy();
            await facet.waitForDeployment();

            const trustDomainFacetInitializer = await new TrustDomainFacetInitializer__factory(deployer).deploy();
            await trustDomainFacetInitializer.waitForDeployment();
            const calldata = trustDomainFacetInitializer.interface.encodeFunctionData("init", [await p256Verifier.getAddress()]);

            const facetCuts = [
                {
                    target: await facet.getAddress(),
                    action: 0,
                    selectors: [
                        // add
                        facet.interface.getFunction("addRootKey").selector,
                        facet.interface.getFunction("addPlatformCAKey").selector,
                        facet.interface.getFunction("addPCK").selector,
                        facet.interface.getFunction("addQE").selector,
                        facet.interface.getFunction("addTD").selector,

                        // revoke
                        facet.interface.getFunction("revokePlatformCA").selector,
                        facet.interface.getFunction("revokePCK").selector,

                        // get
                        facet.interface.getFunction("getRootKey").selector,
                        facet.interface.getFunction("getPlatformCAKey").selector,
                        facet.interface.getFunction("getPCK").selector,
                        facet.interface.getFunction("getQE").selector,
                        facet.interface.getFunction("getTD").selector,
                    ]
                }
            ];

            await (await diamond.diamondCut(facetCuts, await trustDomainFacetInitializer.getAddress(), calldata)).wait();
            return facet;
        }

        export async function addRootKey(diamond: QuexDiamond, owner: HardhatEthersSigner) {
            const tdRegistry = ITrustDomainRegistryExtended__factory.connect(await diamond.getAddress(), diamond.runner);
            await tdRegistry.connect(owner).addRootKey(TestData.rootCaKey);
        }

        export async function addPlatformKey(diamond: QuexDiamond) {
            const tdRegistry = ITrustDomainRegistryExtended__factory.connect(await diamond.getAddress(), diamond.runner);
            const platformCaCert = TestData.platformCaCert;
            await tdRegistry.addPlatformCAKey(
                platformCaCert.x,
                platformCaCert.y,
                platformCaCert.serial,
                platformCaCert.notBefore,
                platformCaCert.extensions,
                platformCaCert.r,
                platformCaCert.s);
        }

        export async function addPCK(diamond: QuexDiamond, processorPckCert: any = undefined){
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

        export async function addQE(diamond: QuexDiamond) {
            const tdRegistry = ITrustDomainRegistryExtended__factory.connect(await diamond.getAddress(), diamond.runner);
            await tdRegistry
                .addQE(
                    TestData.qeReportData,
                    TestData.platformCaCert.serial,
                    TestData.processorPckCert.serial,
                    TestData.qeReportSignature.r,
                    TestData.qeReportSignature.s
                );
        }

        export async function addTD(diamond: QuexDiamond) {
            const tdRegistry = ITrustDomainRegistryExtended__factory.connect(await diamond.getAddress(), diamond.runner);
            await tdRegistry
                .addTD(
                    TestData.tdQuote,
                    1,
                    TestData.attestationKey.x,
                    TestData.attestationKey.y,
                    TestData.qeAuthenticationData,
                    TestData.quoteSignature.r,
                    TestData.quoteSignature.s
                );
        }

        export async function configureFully(diamond: QuexDiamond, owner: HardhatEthersSigner) {
            await addRootKey(diamond, owner);
            await addPlatformKey(diamond);
            await addPCK(diamond);
            await addQE(diamond);
            await addTD(diamond);
        }
    }

    export namespace FeedFacet {
        export async function createAndAddToDiamond(diamond: QuexDiamond, deployer: HardhatEthersSigner) {
            const facet = await new FeedFacet__factory(deployer).deploy();
            await facet.waitForDeployment();

            const facetCuts = [
                {
                    target: await facet.getAddress(),
                    action: 0,
                    selectors: [
                        facet.interface.getFunction("addFeed").selector,
                        facet.interface.getFunction("addPrivatePatch").selector,
                        facet.interface.getFunction("addRequest").selector,
                        facet.interface.getFunction("addResponseSchema").selector,
                        facet.interface.getFunction("allowTDForFeed").selector,
                        facet.interface.getFunction("disallowTDForFeed").selector,
                        facet.interface.getFunction("getFeed").selector,
                        facet.interface.getFunction("isTDAllowedForFeed").selector,
                        facet.interface.getFunction("processFeedResponse").selector,
                        facet.interface.getFunction("sendFeedRequest").selector
                    ]
                }
            ];

            await (await diamond.diamondCut(facetCuts, ethers.ZeroAddress, "0x")).wait();
        }

    }


    export namespace FeedRegistryPolicy {
        export async function deploy() {
            const owner = await getOwner();
            return await ethers.deployContract(
                "V1FeedRegistryPolicy",
                [],
                owner
            );
        }
    }

    export namespace FeedRegistry {
        export async function createConfigured(trustDomainRegistry: V1TrustDomainRegistry) {
            const feedRegistryPolicy = await FeedRegistryPolicy.deploy();
            return deploy(trustDomainRegistry, feedRegistryPolicy);
        }

        async function deploy(trustDomainRegistry: V1TrustDomainRegistry, feedRegistryPolicy: V1FeedRegistryPolicy) {
            const owner = await getOwner();
            return await ethers.deployContract(
                "V1FeedRegistry",
                [owner, await trustDomainRegistry.getAddress(), await feedRegistryPolicy.getAddress()],
                owner
            );
        }

        async function addRequest(feedRegistry: V1FeedRegistry, request: HTTPRequestStruct) {
            const res = await feedRegistry
                .connect(await getOwner())
                .addRequest(request);
            const logs = await ethers.provider.getLogs({ blockHash: res.blockHash! });
            return logs[0].data;
        }

        async function addPatch(feedRegistry: V1FeedRegistry, patch: HTTPPrivatePatchStruct) {
            const res = await feedRegistry
                .connect(await getOwner())
                .addPrivatePatch(1, patch);
            const logs = await ethers.provider.getLogs({ blockHash: res.blockHash! });
            return logs[0].data;
        }

        async function addResponseSchema(feedRegistry: V1FeedRegistry, schema: string) {
            const res = await feedRegistry
                .connect(await getOwner())
                .addResponseSchema(schema);
            const logs = await ethers.provider.getLogs({ blockHash: res.blockHash! });
            return logs[0].data;
        }

        async function addJqFilter(feedRegistry: V1FeedRegistry, filter: string) {
            const res = await feedRegistry
                .connect(await getOwner())
                .addJqFilter(filter);
            const logs = await ethers.provider.getLogs({ blockHash: res.blockHash! });
            return logs[0].data;
        }

        async function addFeed(feedRegistry: V1FeedRegistry, requestId: string, patchId: string, schemaId: string, filterId: string) {
            const res = await feedRegistry
                .connect(await getOwner())
                .addFeed(requestId, patchId, schemaId, filterId);
            const logs = await ethers.provider.getLogs({ blockHash: res.blockHash! });
            return logs[0].data;
        }

        export async function createFeed(feedRegistry: V1FeedRegistry, feed?: FeedStruct) {
            feed ??= {
                request: {
                    method: 0,
                    host: "www.binance.com",
                    path: "/api/v3/ticker/price",
                    headers: [],
                    parameters: [],
                    body: "0x"
                },
                patch: {
                    pathSuffix: "0x",
                    headers: [],
                    parameters: [],
                    body: "0x"
                },
                schema: "int256",
                filter: ".[] | select(.symbol == \"ETHBTC\") | (.price | tonumber * 100000000 | floor)"
            };

            const requestId = await addRequest(feedRegistry, feed.request);
            const patchId = await addPatch(feedRegistry, feed.patch);
            const schemaId = await addResponseSchema(feedRegistry, feed.schema);
            const filterId = await addJqFilter(feedRegistry, feed.filter);
            return await addFeed(feedRegistry, requestId, patchId, schemaId, filterId);
        }

        export namespace Converter {
            export function feedOutputToStruct(feedOutput: FeedStructOutput): FeedStruct {
                const request = feedOutput[0];
                const patch = feedOutput[1];
                return {
                    request: {
                        method: Number(request[0]),
                        host: request[1],
                        path: request[2],
                        headers: request[3].map(x => {
                            return { key: x[0], value: x[1] };
                        }),
                        parameters: request[4].map(x => {
                            return { key: x[0], value: x[1] };
                        }),
                        body: request[5]
                    },
                    patch: {
                        pathSuffix: patch[0],
                        headers: patch[1].map(x => {
                            return { key: x[0], ciphertext: x[1] };
                        }),
                        parameters: patch[2].map(x => {
                            return { key: x[0], ciphertext: x[1] };
                        }),
                        body: patch[3]
                    },
                    schema: feedOutput[2],
                    filter: feedOutput[3]
                };
            }
        }
    }

    export namespace RequestLogic {
        export async function deploy(feedRegistry: V1FeedRegistry, trustDomainRegistry: V1TrustDomainRegistry) {
            const owner = await getOwner();
            return await ethers.deployContract(
                "V1RequestLogic",
                [owner, await feedRegistry.getAddress(), await trustDomainRegistry.getAddress()],
                owner
            );
        }

        export async function addAllowed(requestLogic: V1RequestLogic, contractAddress: string) {
            const owner = await getOwner();
            await requestLogic
                .connect(owner)
                .addAllowedAddress(contractAddress);
        }
    }

    export namespace RequestRegistry {
        export async function createConfigured(feedRegistry: V1FeedRegistry, trustDomainRegistry: V1TrustDomainRegistry) {
            const requestLogic = await RequestLogic.deploy(feedRegistry, trustDomainRegistry);
            const requestRegistry = await deploy(requestLogic);
            await RequestLogic.addAllowed(requestLogic, await requestRegistry.getAddress());
            return requestRegistry;
        }

        async function deploy(requestLogic: V1RequestLogic) {
            const owner = await getOwner();
            return await ethers.deployContract(
                "V1RequestRegistry",
                [owner, await requestLogic.getAddress()],
                owner
            );
        }

        export async function getRequestId(response: ContractTransactionResponse) {
            const logs = await ethers.provider.getLogs({ blockHash: response.blockHash! });
            return logs[0].data.slice(0, 66);
        }

        export async function getRequestPrice(requestRegistry: V1RequestRegistry, requestId: string) {
            const request = await requestRegistry.requests(requestId);
            return request[4];
        }
    }

    export namespace TestQuexResponseProcessor {
        export async function deploy() {
            return await ethers.deployContract("TestQuexResponseProcessor", await getOwner());
        }
    }
}