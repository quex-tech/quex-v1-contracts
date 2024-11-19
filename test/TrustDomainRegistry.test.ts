import {expect} from "chai";
import "@nomicfoundation/hardhat-ethers";
import {takeSnapshot, SnapshotRestorer} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import {V1TrustDomainRegistry} from "../typechain";
import {ContractHelpers} from "./contract_helpers";
import {TDQuoteStruct} from "../typechain/interfaces/IV1QuoteVerifier";

describe("TrustDomainRegistry", function () {
    let trustDomainRegistry: V1TrustDomainRegistry;
    let snapshot: SnapshotRestorer;

    const qeReportData = {
        CPUSVN: "0x0202191b03ff00060000000000000000",
        MISCSELECT: "0x00000000",
        MRENCLAVE: "0xe5a3a7b5d830c2953b98534c6c59a3a34fdc34e933f7f5898f0a85cf08846bca",
        attributes: "0x1500000000000000e700000000000000",
        MRSIGNER: "0xdc9e2a7c6f948f17474e34a7fc43ed030f7c1563f1babddf6340c82e0e54a8c5",
        ISVProdID: "0x0200",
        ISVSVN: "0x0600",
        REPORT_DATA1: "0xb1031521f8c3d582214cf2ad732fabcebab018b821b5b69d838297bf0d2285a9",
        REPORT_DATA2: "0x0000000000000000000000000000000000000000000000000000000000000000",
    };

    const qeReportSignature = {
        r: BigInt("0x5e301006050e5b32024d91d63d916bb90caa81edaee22df41e9de6dafba461f6"),
        s: BigInt("0x4a39eed0ccc11b5769704d9e8e0e4b702412f830e44a72e40033122a76a4aae7"),
    };

    const attestationKey = {
        x: BigInt("0xe677c409ec1f7632b791c907cdb2955c032b4972b971c005bb6711a2f7da7881"),
        y: BigInt("0x1590a686922b5a24191c92595806084b833b659e4aee627f82b60140a131372c"),
    };
    const qeAuthenticationData = "0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f";

    const quoteSignature = {
        r: BigInt("0x22aea7554995bc5ea924ef84808ceebe88726056865564c572e5f6013487ed59"),
        s: BigInt("0xa83caf21fd8fd15841b54fff586f18f5cd2bbeff07cf669a9d423a6c3fe69bed"),
    };

    const tdQuote: TDQuoteStruct = {
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
        REPORT_DATA2: "0x120ed3b57a3f76209c685a04351bf752b166aa8f9b827a97d42bf5df94e1d12b",
    };

    before(async function () {
        const quoteVerifier = await ContractHelpers.QuoteVerifier.createConfigured();
        trustDomainRegistry = await ContractHelpers.TrustDomainRegistry.deploy(quoteVerifier);
        snapshot = await takeSnapshot();
    });

    afterEach(async () => {
        await snapshot.restore();
    });

    it("addQE. Should be performed when all is correct", async () => {
        await expect(trustDomainRegistry
            .connect(await ContractHelpers.getUser())
            .addQE(
                qeReportData,
                ContractHelpers.CertificateVerifier.platformCaCert.serial,
                ContractHelpers.CertificateVerifier.processorPckCert.serial,
                qeReportSignature.r,
                qeReportSignature.s
            ))
            .to.not.rejected;
    });

    it("addQE. Should be rejected when got unknown PCK", async () => {
        const wrongPckSerial = BigInt("0x00cd53aca66dbd5e173beea15185ed20b13a099951");
        await expect(trustDomainRegistry
            .connect(await ContractHelpers.getUser())
            .addQE(
                qeReportData,
                ContractHelpers.CertificateVerifier.platformCaCert.serial,
                wrongPckSerial,
                qeReportSignature.r,
                qeReportSignature.s
            ))
            .to.rejectedWith("Provided PCK not found");
    });

    it("addQE. Should be rejected when signature is incorrect", async () => {
        const wrongSignatureS = BigInt("0x4a39eed0ccc11b5769704d9e8e0e4b702412f830e44a72e40033122a76a4aae8");
        await expect(trustDomainRegistry
            .connect(await ContractHelpers.getUser())
            .addQE(
                qeReportData,
                ContractHelpers.CertificateVerifier.platformCaCert.serial,
                ContractHelpers.CertificateVerifier.processorPckCert.serial,
                qeReportSignature.r,
                wrongSignatureS
            ))
            .to.rejectedWith("Signature is incorrect");
    });

    it("addTD. Should be performed when all is correct", async () => {
        await ContractHelpers.TrustDomainRegistry.addQE(trustDomainRegistry);
        await expect(trustDomainRegistry
            .connect(await ContractHelpers.getUser())
            .addTD(
                tdQuote,
                1,
                attestationKey.x,
                attestationKey.y,
                qeAuthenticationData,
                quoteSignature.r,
                quoteSignature.s
            ))
            .to.not.rejected;
    });

    it("addTD. Should be rejected when wrong QE was chosen", async () => {
        await ContractHelpers.TrustDomainRegistry.addQE(trustDomainRegistry);
        const wrongQeAuthenticationData = "0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1a";
        await expect(trustDomainRegistry
            .connect(await ContractHelpers.getUser())
            .addTD(
                tdQuote,
                1,
                attestationKey.x,
                attestationKey.y,
                wrongQeAuthenticationData,
                quoteSignature.r,
                quoteSignature.s
            ))
            .to.rejectedWith("TD is not related to QE with provided ID");
    });

    it("addTD. Should be rejected when signature is incorrect", async () => {
        await ContractHelpers.TrustDomainRegistry.addQE(trustDomainRegistry);
        const wrongSignatureS = BigInt("0x4a39eed0ccc11b5769704d9e8e0e4b702412f830e44a72e40033122a76a4aae8");
        await expect(trustDomainRegistry
            .connect(await ContractHelpers.getUser())
            .addTD(
                tdQuote,
                1,
                attestationKey.x,
                attestationKey.y,
                qeAuthenticationData,
                quoteSignature.r,
                wrongSignatureS
            ))
            .to.rejectedWith("Signature is incorrect");
    });

    it("addTD. Set correct signer address for TD", async () => {
        const expectedAddress = "0xCa614CD12D3b9515610C4d8b901De4b5641Be508";

        await ContractHelpers.TrustDomainRegistry.addQE(trustDomainRegistry);
        await ContractHelpers.TrustDomainRegistry.addTD(trustDomainRegistry);

        const result = await trustDomainRegistry.getSignerAddress(1);
        expect(result).to.eq(expectedAddress);
    });
})