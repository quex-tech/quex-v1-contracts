import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import {
    ITrustDomainRegistryExtended,
    ITrustDomainRegistryExtended__factory,
    QuexDiamond,
    QuexDiamond__factory,
    TrustDomainFacet
} from "../../../typechain";
import { ethers } from "hardhat";
import { expect } from "chai";
import { ContractHelpers } from "../contract_helpers";
import { SnapshotRestorer, takeSnapshot, time } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import processorPckCert = ContractHelpers.TrustDomainFacet.TestData.processorPckCert;
import platformCaCert = ContractHelpers.TrustDomainFacet.TestData.platformCaCert;
import rootCaKey = ContractHelpers.TrustDomainFacet.TestData.rootCaKey;
import qeReportData = ContractHelpers.TrustDomainFacet.TestData.qeReportData;
import qeReportSignature = ContractHelpers.TrustDomainFacet.TestData.qeReportSignature;
import tdQuote = ContractHelpers.TrustDomainFacet.TestData.tdQuote;
import attestationKey = ContractHelpers.TrustDomainFacet.TestData.attestationKey;
import qeAuthenticationData = ContractHelpers.TrustDomainFacet.TestData.qeAuthenticationData;
import quoteSignature = ContractHelpers.TrustDomainFacet.TestData.quoteSignature;

describe("TrustDomainFacet", () => {
    let owner: SignerWithAddress;
    let nonOwner: SignerWithAddress;

    let diamond: QuexDiamond;
    let trustDomainFacet: TrustDomainFacet;
    let testObject: ITrustDomainRegistryExtended;

    let snapshot: SnapshotRestorer;

    before(async () => {
        [owner, nonOwner] = await ethers.getSigners();
    });

    beforeEach(async () => {
        diamond = await new QuexDiamond__factory(owner).deploy();
        await diamond.init();
        await ContractHelpers.P256VerifierFacet.createAndAddToDiamond(diamond, owner);
        trustDomainFacet = await ContractHelpers.TrustDomainFacet.createAndAddToDiamond(diamond, owner);
        testObject = ITrustDomainRegistryExtended__factory.connect(await diamond.getAddress(), diamond.runner);
        snapshot = await takeSnapshot();
    });

    afterEach(async () => {
        await snapshot.restore();
    });

    describe("#getRootKey", () => {
        it("gets root key", async () => {
            const rootKeyResult = await testObject.getRootKey();
            expect(rootKeyResult.x).to.equal(rootCaKey.x);
            expect(rootKeyResult.y).to.equal(rootCaKey.y);
            expect(rootKeyResult.notBefore).to.equal(rootCaKey.notBefore);
            expect(rootKeyResult.notAfter).to.equal(rootCaKey.notAfter);
        });
    });

    describe("#addPlatformCAKey", () => {
        it("adds platform CA key", async () => {
            await expect(testObject.connect(owner).addPlatformCAKey(
                platformCaCert.x,
                platformCaCert.y,
                platformCaCert.serial,
                platformCaCert.notBefore,
                platformCaCert.notAfter,
                platformCaCert.extensions,
                platformCaCert.r,
                platformCaCert.s
            )).not.to.be.reverted;

            const result = await testObject.getPlatformCAKey(platformCaCert.serial);
            expect(result.x).to.eq(platformCaCert.x);
            expect(result.y).to.eq(platformCaCert.y);
            expect(result.notBefore).to.eq(1526899810n);
            expect(result.notAfter).to.eq(2000285410n);
        });

        describe("reverts if", () => {
            it("signed by not root key", async () => {
                const wrongPlatformCaCert = structuredClone(platformCaCert);
                wrongPlatformCaCert.s = BigInt("17237064055611587912602576747291700467597514190097038271137615530927947838335");
                await expect(testObject
                    .connect(nonOwner)
                    .addPlatformCAKey(
                        wrongPlatformCaCert.x,
                        wrongPlatformCaCert.y,
                        wrongPlatformCaCert.serial,
                        wrongPlatformCaCert.notBefore,
                        wrongPlatformCaCert.notAfter,
                        wrongPlatformCaCert.extensions,
                        wrongPlatformCaCert.r,
                        wrongPlatformCaCert.s
                    ))
                    .to.be.revertedWithCustomError(trustDomainFacet, "InvalidPlatformCertificate");
            });

            it("platform CA is expired", async () => {
                await time.setNextBlockTimestamp(2000285411n);

                await expect(testObject.connect(owner).addPlatformCAKey(
                    platformCaCert.x,
                    platformCaCert.y,
                    platformCaCert.serial,
                    platformCaCert.notBefore,
                    platformCaCert.notAfter,
                    platformCaCert.extensions,
                    platformCaCert.r,
                    platformCaCert.s
                )).to.be.revertedWithCustomError(trustDomainFacet, "Certificate_WrongValidPeriod");
            });
        });
    });

    describe("#addPCK", () => {
        beforeEach(async () => {
            await ContractHelpers.TrustDomainFacet.addPlatformKey(diamond);
        });

        it("adds PCK", async () => {
            await expect(testObject
                .connect(nonOwner)
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
                ))
                .not.to.be.reverted;

            const result = await testObject.getPCK(processorPckCert.authority, processorPckCert.serial);
            expect(result.x).to.eq(processorPckCert.x);
            expect(result.y).to.eq(processorPckCert.y);
            expect(result.notBefore).to.eq(1730719464n);
            expect(result.notAfter).to.eq(1951557864n);
        });

        describe("reverts if", () => {
            it("signed by not registered platform key", async () => {
                const wrongProcessorPckCert = structuredClone(processorPckCert);
                wrongProcessorPckCert.authority = BigInt("0x00cd53aca66dbd5e173beea15185ed20b13a099951");
                await expect(testObject
                    .connect(nonOwner)
                    .addPCK(
                        wrongProcessorPckCert.x,
                        wrongProcessorPckCert.y,
                        wrongProcessorPckCert.serial,
                        wrongProcessorPckCert.notBefore,
                        wrongProcessorPckCert.notAfter,
                        wrongProcessorPckCert.extensions,
                        wrongProcessorPckCert.authority,
                        wrongProcessorPckCert.r,
                        wrongProcessorPckCert.s
                    ))
                    .to.be.revertedWithCustomError(trustDomainFacet, "PlatformCA_NotFound");
            });

            it("pck's signature is wrong", async () => {
                const wrongProcessorPckCert = structuredClone(processorPckCert);
                wrongProcessorPckCert.s = BigInt("0xe2c0d05f02e43cd2e31efb19f7e615206c9dedca72a7e97639691f0d75254e17");
                await expect(testObject
                    .connect(nonOwner)
                    .addPCK(
                        wrongProcessorPckCert.x,
                        wrongProcessorPckCert.y,
                        wrongProcessorPckCert.serial,
                        wrongProcessorPckCert.notBefore,
                        wrongProcessorPckCert.notAfter,
                        wrongProcessorPckCert.extensions,
                        wrongProcessorPckCert.authority,
                        wrongProcessorPckCert.r,
                        wrongProcessorPckCert.s
                    ))
                    .to.be.revertedWithCustomError(trustDomainFacet, "InvalidPCK");
            });

            it("pck is expired", async () => {
                await time.setNextBlockTimestamp(1951557865n);

                await expect(testObject
                    .connect(nonOwner)
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
                    )).to.be.revertedWithCustomError(trustDomainFacet, "Certificate_WrongValidPeriod");
            });
        });
    });

    describe("#addQE", () => {
        beforeEach(async () => {
            await ContractHelpers.TrustDomainFacet.addPlatformKey(diamond);
            await ContractHelpers.TrustDomainFacet.addPCK(diamond);
        });

        it("adds QE", async () => {
            await expect(testObject
                .connect(nonOwner)
                .addQE(
                    qeReportData,
                    platformCaCert.serial,
                    processorPckCert.serial,
                    qeReportSignature.r,
                    qeReportSignature.s
                ))
                .not.to.be.rejected;

            // todo: check get
        });

        describe("reverts if", () => {
            it("signed by not registered PCK", async () => {
                const wrongPckSerial = BigInt("0x00cd53aca66dbd5e173beea15185ed20b13a099951");
                await expect(testObject
                    .connect(nonOwner)
                    .addQE(
                        qeReportData,
                        platformCaCert.serial,
                        wrongPckSerial,
                        qeReportSignature.r,
                        qeReportSignature.s
                    ))
                    .to.be.revertedWithCustomError(trustDomainFacet, "PCKNotFound");
            });

            it("quote's signature is wrong", async () => {
                const wrongSignatureS = BigInt("0x4a39eed0ccc11b5769704d9e8e0e4b702412f830e44a72e40033122a76a4aae8");
                await expect(testObject
                    .connect(nonOwner)
                    .addQE(
                        qeReportData,
                        platformCaCert.serial,
                        processorPckCert.serial,
                        qeReportSignature.r,
                        wrongSignatureS
                    ))
                    .to.be.revertedWithCustomError(trustDomainFacet, "QEReport_InvalidSignature");
            });
        });
    });

    describe("#addTD", () => {
        beforeEach(async () => {
            await ContractHelpers.TrustDomainFacet.addPlatformKey(diamond);
            await ContractHelpers.TrustDomainFacet.addPCK(diamond);
            await ContractHelpers.TrustDomainFacet.addQE(diamond);
        });

        it("adds TD", async () => {
            await expect(testObject
                .connect(nonOwner)
                .addTD(
                    tdQuote,
                    1,
                    attestationKey.x,
                    attestationKey.y,
                    qeAuthenticationData,
                    quoteSignature.r,
                    quoteSignature.s
                ))
                .not.to.be.rejected;
        });

        it("assign expected address", async () => {
            const expectedAddress = ContractHelpers.TrustDomainFacet.TestData.tdAddress;
            await testObject
                .connect(nonOwner)
                .addTD(
                    tdQuote,
                    1,
                    attestationKey.x,
                    attestationKey.y,
                    qeAuthenticationData,
                    quoteSignature.r,
                    quoteSignature.s
                );

            expect((await testObject.getTD(expectedAddress)).TEE_TCB_SVN).not.to.be.eq("0x00000000000000000000000000000000");
        })

        describe("reverts if", () => {
            it("signed by not registered QE", async () => {
                await expect(testObject
                    .connect(nonOwner)
                    .addTD(
                        tdQuote,
                        2,
                        attestationKey.x,
                        attestationKey.y,
                        qeAuthenticationData,
                        quoteSignature.r,
                        quoteSignature.s
                    ))
                    .to.be.revertedWithCustomError(trustDomainFacet, "TDReport_InvalidQuote");
            });

            it("QE's authentication data don't match", async () => {
                const wrongQeAuthenticationData = "0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1a";
                await expect(testObject
                    .connect(nonOwner)
                    .addTD(
                        tdQuote,
                        1,
                        attestationKey.x,
                        attestationKey.y,
                        wrongQeAuthenticationData,
                        quoteSignature.r,
                        quoteSignature.s
                    ))
                    .to.be.revertedWithCustomError(trustDomainFacet, "TDReport_InvalidQuote");
            });

            it("quote's signature is wrong", async () => {
                const wrongSignatureS = BigInt("0x4a39eed0ccc11b5769704d9e8e0e4b702412f830e44a72e40033122a76a4aae8");
                await expect(testObject
                    .connect(nonOwner)
                    .addTD(
                        tdQuote,
                        1,
                        attestationKey.x,
                        attestationKey.y,
                        qeAuthenticationData,
                        quoteSignature.r,
                        wrongSignatureS
                    ))
                    .to.be.revertedWithCustomError(trustDomainFacet, "TDReport_InvalidSignature");
            })
        });
    });

    describe("#revokePCK", () => {
        beforeEach(async () => {
            await ContractHelpers.TrustDomainFacet.addPlatformKey(diamond);
            await ContractHelpers.TrustDomainFacet.addPCK(diamond);
        });

        describe("reverts if", () => {
            it("sender is not owner", async () => {
                await expect(testObject
                    .connect(nonOwner)
                    .revokePCK(
                        processorPckCert.authority,
                        processorPckCert.serial))
                    .to.be.revertedWithCustomError(diamond, "Ownable__NotOwner");
            });
        });
    });

    describe("#revokePlatformCA", () => {
        beforeEach(async () => {
            await ContractHelpers.TrustDomainFacet.addPlatformKey(diamond);
        });
        
        it("revokes platform CA", async () => {
            await expect(testObject
                .connect(owner)
                .revokePlatformCA(platformCaCert.serial)
            ).not.to.be.reverted;
            
            expect((await testObject.getPlatformCAKey(platformCaCert.serial)).x).to.be.eq(0n);
        });
        
        it("revokes all related PCKs", async () => {
            const anotherProcessorPckCert = {
                x: BigInt("0x99158f75763e8fc5e1dab9e542cb410e94decda1e46fdfbd57d996a7086c5731"),
                y: BigInt("0xb77c15cb4d3d7ef849bc170c67ba18a2f3cce1c723477a0bb52bd1af274bcb8f"),
                serial: BigInt("0xe1d36308908c642b4e39a77dfd2c18a8cf4811"),
                notBefore: "0x3234303831353137303031395a",
                notAfter: "0x3331303831353137303031395a",
                extensions:
                    "0x30820308301f0603551d23041830168014956f5dcdbd1be1e94049c9d4f433ce01570bde54306b0603551d1f046430623060a05ea05c865a68747470733a2f2f6170692e7472757374656473657276696365732e696e74656c2e636f6d2f7367782f63657274696669636174696f6e2f76342f70636b63726c3f63613d706c6174666f726d26656e636f64696e673d646572301d0603551d0e041604143e4c15958d7554ad930524d9da6600305683c508300e0603551d0f0101ff0404030206c0300c0603551d130101ff040230003082023906092a864886f84d010d010482022a30820226301e060a2a864886f84d010d010104106ca004e799459e298c07ccd7af00c24e30820163060a2a864886f84d010d0102308201533010060b2a864886f84d010d0102010201023010060b2a864886f84d010d0102020201023010060b2a864886f84d010d0102030201023010060b2a864886f84d010d0102040201023010060b2a864886f84d010d0102050201033010060b2a864886f84d010d0102060201013010060b2a864886f84d010d0102070201003010060b2a864886f84d010d0102080201033010060b2a864886f84d010d0102090201003010060b2a864886f84d010d01020a0201003010060b2a864886f84d010d01020b0201003010060b2a864886f84d010d01020c0201003010060b2a864886f84d010d01020d0201003010060b2a864886f84d010d01020e0201003010060b2a864886f84d010d01020f0201003010060b2a864886f84d010d0102100201003010060b2a864886f84d010d01021102010b301f060b2a864886f84d010d0102120410020202020301000300000000000000003010060a2a864886f84d010d0103040200003014060a2a864886f84d010d01040406b0c06f000000300f060a2a864886f84d010d01050a0101301e060a2a864886f84d010d010604103aac4e3ec60fbaf6933812a1d21169a33044060a2a864886f84d010d010730363010060b2a864886f84d010d0107010101ff3010060b2a864886f84d010d0107020101ff3010060b2a864886f84d010d0107030101ff",
                authority: BigInt("0x956f5dcdbd1be1e94049c9d4f433ce01570bde54"),
                r: BigInt("0x4AED5C07C590310B27F53E021634CB8B63E2B084DFFEDCF725E0D1675D6C9479"),
                s: BigInt("0xEF8A50030D245365B227720F45AC2E11D61AE52A32C3AD57AABA0A051ABE9578"),
            };

            await ContractHelpers.TrustDomainFacet.addPCK(diamond);
            await ContractHelpers.TrustDomainFacet.addPCK(diamond, anotherProcessorPckCert);

            expect((await testObject.getPCK(processorPckCert.authority, processorPckCert.serial)).x).not.to.be.eq(0);
            expect((await testObject.getPCK(anotherProcessorPckCert.authority, anotherProcessorPckCert.serial)).x).not.to.be.eq(0);

            expect(processorPckCert.authority).to.eq(anotherProcessorPckCert.authority, "Test expects same platform CA for all PCKs");

            await testObject
                .connect(owner)
                .revokePlatformCA(platformCaCert.serial);

            expect((await testObject.getPCK(processorPckCert.authority, processorPckCert.serial)).x).to.be.eq(0);
            expect((await testObject.getPCK(anotherProcessorPckCert.authority, anotherProcessorPckCert.serial)).x).to.be.eq(0);
        });

        describe("reverts if", () => {
            it("sender is not owner", async () => {
                await expect(testObject
                    .connect(nonOwner)
                    .revokePlatformCA(platformCaCert.serial)
                ).to.be.revertedWithCustomError(diamond, "Ownable__NotOwner");
            });
        });

        describe("#isTDValid", () => {
            beforeEach(async () => {
                await ContractHelpers.TrustDomainFacet.addPlatformKey(diamond);
                await ContractHelpers.TrustDomainFacet.addPCK(diamond);
                await ContractHelpers.TrustDomainFacet.addQE(diamond);
            });
    
            it("returns true if TD is registered", async () => {
                await ContractHelpers.TrustDomainFacet.addTD(diamond);

                expect(await testObject.isTDValid(ContractHelpers.TrustDomainFacet.TestData.tdAddress))
                    .to.be.true;
            });
    
            it("returns false if TD is not registered", async () => {
                expect(await testObject.isTDValid(ContractHelpers.TrustDomainFacet.TestData.tdAddress))
                    .to.be.false;
            });
        });
    });
});