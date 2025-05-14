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

        it("emits PlatformCAAdded event", async () => {
            await expect(testObject.connect(owner).addPlatformCAKey(
                platformCaCert.x,
                platformCaCert.y,
                platformCaCert.serial,
                platformCaCert.notBefore,
                platformCaCert.notAfter,
                platformCaCert.extensions,
                platformCaCert.r,
                platformCaCert.s
            )).to.emit(testObject, "PlatformCAAdded")
            .withArgs(platformCaCert.serial);
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
                )).to.be.revertedWithCustomError(trustDomainFacet, "Certificate_WrongValidityPeriod");
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

        it("emits PCKAdded event", async () => {
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
                .to.emit(testObject, "PCKAdded")
                .withArgs(processorPckCert.authority, processorPckCert.serial);
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
                    )).to.be.revertedWithCustomError(trustDomainFacet, "Certificate_WrongValidityPeriod");
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

        it("emits QEReportAdded event", async () => {
            await expect(testObject
                .connect(nonOwner)
                .addQE(
                    qeReportData,
                    platformCaCert.serial,
                    processorPckCert.serial,
                    qeReportSignature.r,
                    qeReportSignature.s
                ))
                .to.emit(testObject, "QEReportAdded")
                .withArgs(1);
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

        it("emits TDReportAdded event", async () => {
            const tx = await testObject
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
            
            const receipt = await tx.wait();
            const event = receipt?.logs[0];
            if (!event) throw new Error("No event found");
            const parsedEvent = testObject.interface.parseLog(event);
            const tdId = parsedEvent?.args[0] as bigint;

            await expect(tx)
                .to.emit(testObject, "TDReportAdded")
                .withArgs(tdId);
        });

        it("assign expected address", async () => {
            const expectedAddress = ContractHelpers.TrustDomainFacet.TestData.tdAddress;
            const tdId = await ContractHelpers.TrustDomainFacet.addTD(diamond);

            expect((await testObject.getTDSignerAddress(tdId))).to.be.eq(expectedAddress);
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

        it("revokes PCK", async () => {
            await expect(testObject
                .connect(owner)
                .revokePCK(processorPckCert.authority, processorPckCert.serial)
            ).not.to.be.reverted;

            const pck = await testObject.getPCK(processorPckCert.authority, processorPckCert.serial);
            expect(pck.x).to.be.eq(0n);
        });

        it("emits PCKRevoked event", async () => {
            await expect(testObject
                .connect(owner)
                .revokePCK(processorPckCert.authority, processorPckCert.serial)
            ).to.emit(testObject, "PCKRevoked")
            .withArgs(processorPckCert.authority, processorPckCert.serial);
        });

        it("can revoke PCK after all QEs are revoked", async () => {
            const qeId = await ContractHelpers.TrustDomainFacet.addQE(diamond);
            
            const qeReport = await testObject.getQE(qeId);
            expect(qeReport.REPORT_DATA1).not.to.be.eq(0n);

            await testObject
                .connect(owner)
                .revokeQE(qeId);

            await expect(testObject
                .connect(owner)
                .revokePCK(processorPckCert.authority, processorPckCert.serial)
            ).not.to.be.reverted;

            const pck = await testObject.getPCK(processorPckCert.authority, processorPckCert.serial);
            expect(pck.x).to.be.eq(0n);
        });

        describe("reverts if", () => {
            it("sender is not owner", async () => {
                await expect(testObject
                    .connect(nonOwner)
                    .revokePCK(processorPckCert.authority, processorPckCert.serial)
                ).to.be.revertedWithCustomError(diamond, "Ownable__NotOwner");
            });

            it("PCK has associated QEs", async () => {
                await ContractHelpers.TrustDomainFacet.addQE(diamond);

                await expect(testObject
                    .connect(owner)
                    .revokePCK(processorPckCert.authority, processorPckCert.serial)
                ).to.be.revertedWithCustomError(trustDomainFacet, "PCKRevocation_QEExist");
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

        it("emits PlatformCARevoked event", async () => {
            await expect(testObject
                .connect(owner)
                .revokePlatformCA(platformCaCert.serial)
            ).to.emit(testObject, "PlatformCARevoked")
            .withArgs(platformCaCert.serial);
        });

        it("can revoke platform CA after all PCKs are revoked", async () => {
            await ContractHelpers.TrustDomainFacet.addPCK(diamond);
            
            const pck = await testObject.getPCK(processorPckCert.authority, processorPckCert.serial);
            expect(pck.x).not.to.be.eq(0n);

            await testObject
                .connect(owner)
                .revokePCK(processorPckCert.authority, processorPckCert.serial);

            await expect(testObject
                .connect(owner)
                .revokePlatformCA(platformCaCert.serial)
            ).not.to.be.reverted;

            expect((await testObject.getPlatformCAKey(platformCaCert.serial)).x).to.be.eq(0n);
        });
        
        describe("reverts if", () => {
            it("sender is not owner", async () => {
                await expect(testObject
                    .connect(nonOwner)
                    .revokePlatformCA(platformCaCert.serial)
                ).to.be.revertedWithCustomError(diamond, "Ownable__NotOwner");
            });

            it("platform CA has associated PCKs", async () => {
                await ContractHelpers.TrustDomainFacet.addPCK(diamond);
                
                await expect(testObject
                    .connect(owner)
                    .revokePlatformCA(platformCaCert.serial)
                ).to.be.revertedWithCustomError(trustDomainFacet, "PlatformCARevocation_PCKsExist");
            });
        });
    });

    describe("#isTDValid", () => {
        beforeEach(async () => {
            await ContractHelpers.TrustDomainFacet.addPlatformKey(diamond);
            await ContractHelpers.TrustDomainFacet.addPCK(diamond);
            await ContractHelpers.TrustDomainFacet.addQE(diamond);
        });

        it("returns true if TD is registered", async () => {
            const tdId = await ContractHelpers.TrustDomainFacet.addTD(diamond);

            expect(await testObject.isTDValid(tdId))
                .to.be.true;
        });

        it("returns false if TD is not registered", async () => {
            const tdId = 123
            expect(await testObject.isTDValid(tdId))
                .to.be.false;
        });
    });

    describe("#revokeQE", () => {
        let qeId: bigint;

        beforeEach(async () => {
            await ContractHelpers.TrustDomainFacet.addPlatformKey(diamond);
            await ContractHelpers.TrustDomainFacet.addPCK(diamond);
            qeId = await ContractHelpers.TrustDomainFacet.addQE(diamond);
        });

        it("revokes QE", async () => {
            await expect(testObject
                .connect(owner)
                .revokeQE(qeId)
            ).not.to.be.reverted;

            const qeReport = await testObject.getQE(qeId);
            expect(qeReport.REPORT_DATA1).to.equal(0n);
        });

        it("emits QEReportRevoked event", async () => {
            await expect(testObject
                .connect(owner)
                .revokeQE(qeId)
            ).to.emit(testObject, "QEReportRevoked")
            .withArgs(qeId);
        });

        it("can revoke QE after its TD is revoked", async () => {
            const tdId = await ContractHelpers.TrustDomainFacet.addTD(diamond);
            
            await expect(testObject
                .connect(owner)
                .revokeTD(tdId)
            ).not.to.be.reverted;

            await expect(testObject
                .connect(owner)
                .revokeQE(qeId)
            ).not.to.be.reverted;

            const qeReport = await testObject.getQE(qeId);
            expect(qeReport.REPORT_DATA1).to.equal(0n);
        });

        describe("reverts if", () => {
            it("sender is not owner", async () => {
                await expect(testObject
                    .connect(nonOwner)
                    .revokeQE(qeId)
                ).to.be.revertedWithCustomError(diamond, "Ownable__NotOwner");
            });

            it("QE has associated TDs", async () => {
                await ContractHelpers.TrustDomainFacet.addTD(diamond);

                await expect(testObject
                    .connect(owner)
                    .revokeQE(qeId)
                ).to.be.revertedWithCustomError(trustDomainFacet, "QERevocation_TDExist");
            });
        });
    });

    describe("#revokeTD", () => {
        let tdId: bigint;

        beforeEach(async () => {
            await ContractHelpers.TrustDomainFacet.addPlatformKey(diamond);
            await ContractHelpers.TrustDomainFacet.addPCK(diamond);
            await ContractHelpers.TrustDomainFacet.addQE(diamond);
            // Add TD and store its ID
            const tx = await testObject.addTD(
                tdQuote,
                1,
                attestationKey.x,
                attestationKey.y,
                qeAuthenticationData,
                quoteSignature.r,
                quoteSignature.s
            );
            const receipt = await tx.wait();
            const event = receipt?.logs[0];
            if (!event) throw new Error("No event found");
            const parsedEvent = testObject.interface.parseLog(event);
            tdId = parsedEvent?.args[0] as bigint;
        });

        it("revokes TD", async () => {
            await expect(testObject
                .connect(owner)
                .revokeTD(tdId)
            ).not.to.be.reverted;

            // Verify TD is revoked by checking its data is cleared
            const tdQuote = await testObject.getTD(tdId);
            expect(tdQuote.REPORT_DATA1).to.equal(0n);
            expect(await testObject.getTDSignerAddress(tdId)).to.equal(ethers.ZeroAddress);
        });

        it("emits TDReportRevoked event", async () => {
            await expect(testObject
                .connect(owner)
                .revokeTD(tdId)
            ).to.emit(testObject, "TDReportRevoked")
            .withArgs(tdId);
        });

        describe("reverts if", () => {
            it("sender is not owner", async () => {
                await expect(testObject
                    .connect(nonOwner)
                    .revokeTD(tdId)
                ).to.be.revertedWithCustomError(diamond, "Ownable__NotOwner");
            });
        });
    });
});