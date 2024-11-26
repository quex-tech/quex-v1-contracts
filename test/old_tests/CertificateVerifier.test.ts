import {expect} from "chai";
import "@nomicfoundation/hardhat-ethers";
import {takeSnapshot, SnapshotRestorer} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import {V1CertificateVerifier} from "../../typechain";
import {ContractHelpers} from "./contract_helpers";
import processorPckCert = ContractHelpers.CertificateVerifier.processorPckCert;

describe("TrustDomainRegistry", function () {
    let certificateVerifier: V1CertificateVerifier;
    let snapshot: SnapshotRestorer;

    before(async function () {
        const p256Verifier = await ContractHelpers.P256Verifier.deploy();
        certificateVerifier = await ContractHelpers.CertificateVerifier.deploy(p256Verifier);
        snapshot = await takeSnapshot();
    });

    afterEach(async () => {
        await snapshot.restore();
    });

    it("addPlatformCAKey. Platform CA signed by root key should pass", async () => {
        await ContractHelpers.CertificateVerifier.addRootKey(certificateVerifier);
        const platformCaCert = structuredClone(ContractHelpers.CertificateVerifier.platformCaCert);
        await expect(certificateVerifier
            .connect(await ContractHelpers.getUser())
            .addPlatformCAKey(
                platformCaCert.x,
                platformCaCert.y,
                platformCaCert.serial,
                platformCaCert.not_before,
                platformCaCert.extensions,
                platformCaCert.r,
                platformCaCert.s
            ))
            .to.not.reverted;
    });

    it("addPlatformCAKey. Platform CA signed by not root key should be rejected", async () => {
        await ContractHelpers.CertificateVerifier.addRootKey(certificateVerifier);
        const platformCaCert = structuredClone(ContractHelpers.CertificateVerifier.platformCaCert);
        platformCaCert.s = BigInt("17237064055611587912602576747291700467597514190097038271137615530927947838335");
        await expect(certificateVerifier
            .connect(await ContractHelpers.getUser())
            .addPlatformCAKey(
                platformCaCert.x,
                platformCaCert.y,
                platformCaCert.serial,
                platformCaCert.not_before,
                platformCaCert.extensions,
                platformCaCert.r,
                platformCaCert.s
            ))
            .to.be.revertedWith("Signature is invalid");
    });

    it("addPCK. PCK signed by known platform CA should pass", async () => {
        await ContractHelpers.CertificateVerifier.addRootKey(certificateVerifier);
        await ContractHelpers.CertificateVerifier.addPlatformCAKey(certificateVerifier);
        const processorPckCert = structuredClone(ContractHelpers.CertificateVerifier.processorPckCert);
        await expect(certificateVerifier
            .connect(await ContractHelpers.getUser())
            .addPCK(
                processorPckCert.x,
                processorPckCert.y,
                processorPckCert.serial,
                processorPckCert.not_before,
                processorPckCert.not_after,
                processorPckCert.extensions,
                processorPckCert.authority,
                processorPckCert.r,
                processorPckCert.s
            ))
            .to.not.reverted;
    });

    it("addPCK. PCK signed by unknown platform CA should be rejected", async () => {
        await ContractHelpers.CertificateVerifier.addRootKey(certificateVerifier);
        await ContractHelpers.CertificateVerifier.addPlatformCAKey(certificateVerifier);
        const processorPckCert = structuredClone(ContractHelpers.CertificateVerifier.processorPckCert);
        processorPckCert.authority = BigInt("0x00cd53aca66dbd5e173beea15185ed20b13a099951");
        await expect(certificateVerifier
            .connect(await ContractHelpers.getUser())
            .addPCK(
                processorPckCert.x,
                processorPckCert.y,
                processorPckCert.serial,
                processorPckCert.not_before,
                processorPckCert.not_after,
                processorPckCert.extensions,
                processorPckCert.authority,
                processorPckCert.r,
                processorPckCert.s
            ))
            .to.revertedWith("Couldn't find related platform CA");
    });

    it("addPCK. PCK with wrong signature should be rejected", async () => {
        await ContractHelpers.CertificateVerifier.addRootKey(certificateVerifier);
        await ContractHelpers.CertificateVerifier.addPlatformCAKey(certificateVerifier);
        const processorPckCert = structuredClone(ContractHelpers.CertificateVerifier.processorPckCert);
        processorPckCert.s = BigInt("0xe2c0d05f02e43cd2e31efb19f7e615206c9dedca72a7e97639691f0d75254e17");
        await expect(certificateVerifier
            .connect(await ContractHelpers.getUser())
            .addPCK(
                processorPckCert.x,
                processorPckCert.y,
                processorPckCert.serial,
                processorPckCert.not_before,
                processorPckCert.not_after,
                processorPckCert.extensions,
                processorPckCert.authority,
                processorPckCert.r,
                processorPckCert.s
            ))
            .to.revertedWith("Signature is invalid");
    });

    it("getPCK should return correct ECKey", async () => {
        await ContractHelpers.CertificateVerifier.addRootKey(certificateVerifier);
        await ContractHelpers.CertificateVerifier.addPlatformCAKey(certificateVerifier);
        const processorPckCert = structuredClone(ContractHelpers.CertificateVerifier.processorPckCert);
        await certificateVerifier
            .connect(await ContractHelpers.getUser())
            .addPCK(
                processorPckCert.x,
                processorPckCert.y,
                processorPckCert.serial,
                processorPckCert.not_before,
                processorPckCert.not_after,
                processorPckCert.extensions,
                processorPckCert.authority,
                processorPckCert.r,
                processorPckCert.s
            );
        const result = await certificateVerifier.getPCK(processorPckCert.authority, processorPckCert.serial);
        expect(result.x).to.eq(processorPckCert.x);
        expect(result.y).to.eq(processorPckCert.y);
        expect(result.not_before).to.eq(1730719464n);
        expect(result.not_after).to.eq(1951557864n);
    });

    it("revokePCK. Not owner should be rejected", async () => {
        await expect(certificateVerifier
            .connect(await ContractHelpers.getUser())
            .revokePCK(processorPckCert.authority, processorPckCert.serial))
            .to.be.revertedWithCustomError(certificateVerifier, "OwnableUnauthorizedAccount");
    });

    it("revokePlatformCA. Not owner should be rejected", async () => {
        await expect(certificateVerifier
            .connect(await ContractHelpers.getUser())
            .revokePlatformCA(processorPckCert.authority))
            .to.be.revertedWithCustomError(certificateVerifier, "OwnableUnauthorizedAccount");
    });

    it("revokePlatformCA. Should revoke all related PCK", async () => {
        await ContractHelpers.CertificateVerifier.addRootKey(certificateVerifier);
        await ContractHelpers.CertificateVerifier.addPlatformCAKey(certificateVerifier);
        await certificateVerifier
            .connect(await ContractHelpers.getUser())
            .addPCK(
                processorPckCert.x,
                processorPckCert.y,
                processorPckCert.serial,
                processorPckCert.not_before,
                processorPckCert.not_after,
                processorPckCert.extensions,
                processorPckCert.authority,
                processorPckCert.r,
                processorPckCert.s
            );

        const anotherProcessorPckCert = {
            x: BigInt("0x99158f75763e8fc5e1dab9e542cb410e94decda1e46fdfbd57d996a7086c5731"),
            y: BigInt("0xb77c15cb4d3d7ef849bc170c67ba18a2f3cce1c723477a0bb52bd1af274bcb8f"),
            serial: BigInt("0xe1d36308908c642b4e39a77dfd2c18a8cf4811"),
            not_before: "0x3234303831353137303031395a",
            not_after: "0x3331303831353137303031395a",
            extensions:
                "0x30820308301f0603551d23041830168014956f5dcdbd1be1e94049c9d4f433ce01570bde54306b0603551d1f046430623060a05ea05c865a68747470733a2f2f6170692e7472757374656473657276696365732e696e74656c2e636f6d2f7367782f63657274696669636174696f6e2f76342f70636b63726c3f63613d706c6174666f726d26656e636f64696e673d646572301d0603551d0e041604143e4c15958d7554ad930524d9da6600305683c508300e0603551d0f0101ff0404030206c0300c0603551d130101ff040230003082023906092a864886f84d010d010482022a30820226301e060a2a864886f84d010d010104106ca004e799459e298c07ccd7af00c24e30820163060a2a864886f84d010d0102308201533010060b2a864886f84d010d0102010201023010060b2a864886f84d010d0102020201023010060b2a864886f84d010d0102030201023010060b2a864886f84d010d0102040201023010060b2a864886f84d010d0102050201033010060b2a864886f84d010d0102060201013010060b2a864886f84d010d0102070201003010060b2a864886f84d010d0102080201033010060b2a864886f84d010d0102090201003010060b2a864886f84d010d01020a0201003010060b2a864886f84d010d01020b0201003010060b2a864886f84d010d01020c0201003010060b2a864886f84d010d01020d0201003010060b2a864886f84d010d01020e0201003010060b2a864886f84d010d01020f0201003010060b2a864886f84d010d0102100201003010060b2a864886f84d010d01021102010b301f060b2a864886f84d010d0102120410020202020301000300000000000000003010060a2a864886f84d010d0103040200003014060a2a864886f84d010d01040406b0c06f000000300f060a2a864886f84d010d01050a0101301e060a2a864886f84d010d010604103aac4e3ec60fbaf6933812a1d21169a33044060a2a864886f84d010d010730363010060b2a864886f84d010d0107010101ff3010060b2a864886f84d010d0107020101ff3010060b2a864886f84d010d0107030101ff",
            authority: BigInt("0x956f5dcdbd1be1e94049c9d4f433ce01570bde54"),
            r: BigInt("0x4AED5C07C590310B27F53E021634CB8B63E2B084DFFEDCF725E0D1675D6C9479"),
            s: BigInt("0xEF8A50030D245365B227720F45AC2E11D61AE52A32C3AD57AABA0A051ABE9578"),
        };

        await certificateVerifier
            .connect(await ContractHelpers.getUser())
            .addPCK(
                anotherProcessorPckCert.x,
                anotherProcessorPckCert.y,
                anotherProcessorPckCert.serial,
                anotherProcessorPckCert.not_before,
                anotherProcessorPckCert.not_after,
                anotherProcessorPckCert.extensions,
                anotherProcessorPckCert.authority,
                anotherProcessorPckCert.r,
                anotherProcessorPckCert.s
            );

        expect(processorPckCert.authority).to.eq(anotherProcessorPckCert.authority, "Test expects same platform CA for all PCKs");

        await certificateVerifier
            .connect(await ContractHelpers.getOwner())
            .revokePlatformCA(processorPckCert.authority);

        expect((await certificateVerifier.getPCK(processorPckCert.authority, processorPckCert.serial)).x).to.eq(0n);
        expect((await certificateVerifier.getPCK(anotherProcessorPckCert.authority, anotherProcessorPckCert.serial)).x).to.eq(0n);
    });
})