import env, { ignition } from "hardhat";
import { QuexNetworkConfig, quexConfig } from "./quex_config";
import { ITrustDomainRegistryExtended, ITrustDomainRegistryExtended__factory } from "../typechain";
import { QEReportStruct, TDQuoteStruct } from "../typechain/contracts/facets/trust_domain/TrustDomainFacet";
import { ethers, BytesLike, EventLog } from "ethers";
import * as asn1js from "asn1js";
import QuexCoreCompleteDeployAndConfigurationModule from "../ignition/modules/core/QuexCoreCompleteDeployAndConfigurationModule";



interface AddQEArgs {
    qeReport: QEReportStruct;
    platformSerial: bigint;
    pckSerial: bigint;
    r: bigint;
    s: bigint;
}

interface AddTDArgs {
    tdQuote: TDQuoteStruct;
    x: bigint;
    y: bigint;
    authenticationData: BytesLike;
    r: bigint;
    s: bigint;
}

interface CertificateData {
    serial: bigint;
    notBefore: string;
    notAfter: string;
    extensions: string;
    x: bigint;
    y: bigint;
    authority: string;
    r: bigint;
    s: bigint;
}

async function run(quexNetworkConfig: QuexNetworkConfig, quoteData: any) {
    const { quexCoreDiamond } = await ignition.deploy(QuexCoreCompleteDeployAndConfigurationModule, { strategy: quexNetworkConfig.disableCreate2 ? "basic" : "create2" });
    const trustDomainRegistry = ITrustDomainRegistryExtended__factory.connect(await quexCoreDiamond.getAddress(), quexCoreDiamond.runner);
    const { platformCA, processorPck } = parseCertificates(quoteData.quote_signature_data.qe_certification_data.certification_data.qe_certification_data.certification_data);
    const addQEArgs = parseQE(quoteData, platformCA, processorPck);
    const addTDArgs = parseTdQuote(quoteData);

    const calculatedTdId = calculateTDId(addTDArgs.tdQuote);
    if (await isTDRegistered(trustDomainRegistry, calculatedTdId)) {
        console.log(`TD with id ${calculatedTdId} already registered`);
        return;
    }

    await addPlatformCA(trustDomainRegistry, platformCA);
    await addProcessorPck(trustDomainRegistry, processorPck);
    const qeId = await addQE(trustDomainRegistry, addQEArgs);
    const tdId = await addTD(trustDomainRegistry, qeId, addTDArgs);
    if (tdId != calculatedTdId) {
        console.log(`Calculated TD id is not the same as the one returned by the contract: ${calculatedTdId} != ${tdId}`);
    }
}

function parseCertificates(certificationData: string): { platformCA: CertificateData, processorPck: CertificateData } {
    const certificates = Buffer.from(certificationData, 'base64').toString()
        .split("-----END CERTIFICATE-----")
        .map(pem => pem + "-----END CERTIFICATE-----");

    const processorPck = parsePemCert(certificates[0]);
    const platformCA = parsePemCert(certificates[1]);

    return { platformCA, processorPck };
}

function parseQE(quoteData: any, platformCA: CertificateData, processorPck: CertificateData): AddQEArgs {
    const qeReportRaw = quoteData.quote_signature_data.qe_certification_data.certification_data.qe_report;

    const reportData = base64ToHexBytes(qeReportRaw.report_data).slice(2);

    const qeReport: QEReportStruct = {
        CPUSVN: base64ToHexBytes(qeReportRaw.cpu_svn),
        MISCSELECT: intToHexBytes(qeReportRaw.miscselect, 4),
        attributes: base64ToHexBytes(qeReportRaw.attributes),
        MRENCLAVE: base64ToHexBytes(qeReportRaw.mrenclave),
        MRSIGNER: base64ToHexBytes(qeReportRaw.mrsigner),
        ISVProdID: intToHexBytes(qeReportRaw.isv_prodID, 2),
        ISVSVN: intToHexBytes(qeReportRaw.isv_svn, 2),
        REPORT_DATA1: "0x" + reportData.slice(0, 64),
        REPORT_DATA2: "0x" + reportData.slice(64, 128),
    };

    const qeReportSignature = quoteData.quote_signature_data.qe_certification_data.certification_data.qe_report_signature;

    return {
        qeReport,
        platformSerial: platformCA.serial,
        pckSerial: processorPck.serial,
        r: base64ToBigInt(qeReportSignature.r),
        s: base64ToBigInt(qeReportSignature.s),
    }
}

function parseTdQuote(quoteData: any): AddTDArgs {
    const tdQuoteRaw = quoteData.td_quote_body;

    const reportData = base64ToHexBytes(tdQuoteRaw.reportdata).slice(2);

    const tdQuote: TDQuoteStruct = {
        USER_DATA: base64ToHexBytes(quoteData.quote_header.user_data),
        TEE_TCB_SVN: base64ToHexBytes(tdQuoteRaw.tcb_svn),
        MRSEAM: base64ToHexBytes(tdQuoteRaw.mrseam),
        MRSIGNERSEAM: base64ToHexBytes(tdQuoteRaw.mrsignerseam),
        SEAMATTRIBUTES: base64ToHexBytes(tdQuoteRaw.seamattributes),
        TDATTRIBUTES: base64ToHexBytes(tdQuoteRaw.tdattributes),
        XFAM: base64ToHexBytes(tdQuoteRaw.xfam),
        MRTD: base64ToHexBytes(tdQuoteRaw.mrtd),
        MRCONFIGID: base64ToHexBytes(tdQuoteRaw.mrconfigid),
        MROWNER: base64ToHexBytes(tdQuoteRaw.mrowner),
        MROWNERCONFIG: base64ToHexBytes(tdQuoteRaw.mrownerconfig),
        RTMR0: base64ToHexBytes(tdQuoteRaw.rtmr0),
        RTMR1: base64ToHexBytes(tdQuoteRaw.rtmr1),
        RTMR2: base64ToHexBytes(tdQuoteRaw.rtmr2),
        RTMR3: base64ToHexBytes(tdQuoteRaw.rtmr3),
        REPORT_DATA1: "0x" + reportData.slice(0, 64),
        REPORT_DATA2: "0x" + reportData.slice(64, 128),
    };

    const attestationKey = quoteData.quote_signature_data.ecdsa_attestation_key;
    const quoteSignature = quoteData.quote_signature_data.quote_signature;

    return {
        tdQuote,
        x: base64ToBigInt(attestationKey.x),
        y: base64ToBigInt(attestationKey.y),
        authenticationData: base64ToHexBytes(quoteData.quote_signature_data.qe_certification_data.certification_data.qe_authentication_data.data),
        r: base64ToBigInt(quoteSignature.r),
        s: base64ToBigInt(quoteSignature.s),
    }
}

async function addPlatformCA(tdRegistry: ITrustDomainRegistryExtended, platformCA: CertificateData) {
    const existingPlatformCA = await tdRegistry.getPlatformCAKey(platformCA.serial);
    if (existingPlatformCA.x != 0n) {
        console.log(`Platform CA with serial ${platformCA.serial} already exists`);
        return;
    }

    const tx = await tdRegistry.addPlatformCAKey(
        platformCA.x,
        platformCA.y,
        platformCA.serial,
        platformCA.notBefore,
        platformCA.notAfter,
        platformCA.extensions,
        platformCA.r,
        platformCA.s
    );
    await tx.wait();
    console.log(`Platform CA with serial ${platformCA.serial} added`);
}

async function addProcessorPck(tdRegistry: ITrustDomainRegistryExtended, processorPck: CertificateData) {
    const existingProcessorPck = await tdRegistry.getPCK(processorPck.authority, processorPck.serial);
    if (existingProcessorPck.x != 0n) {
        console.log(`Processor PCK with serial ${processorPck.serial} already exists`);
        return;
    }

    const tx = await tdRegistry.addPCK(
        processorPck.x,
        processorPck.y,
        processorPck.serial,
        processorPck.notBefore,
        processorPck.notAfter,
        processorPck.extensions,
        processorPck.authority,
        processorPck.r,
        processorPck.s
    );
    await tx.wait();
    console.log(`Processor PCK with serial ${processorPck.serial} added`);
}

async function addQE(tdRegistry: ITrustDomainRegistryExtended, addQEArgs: AddQEArgs) {
    console.log(`Adding QE with report:\n${JSON.stringify(addQEArgs.qeReport, null, 2)}`);
    const tx = await tdRegistry.addQE(
        addQEArgs.qeReport,
        addQEArgs.platformSerial,
        addQEArgs.pckSerial,
        addQEArgs.r,
        addQEArgs.s
    );
    const receipt = await tx.wait();
    const qeId = (<EventLog>receipt?.logs[0]).args[0];
    console.log(`QE added with id: ${qeId}`);
    return qeId;
}

async function addTD(tdRegistry: ITrustDomainRegistryExtended, qeId: bigint, addTDArgs: AddTDArgs) {
    console.log(`Adding TD with quote:\n${JSON.stringify(addTDArgs.tdQuote, null, 2)}`);
    const tx = await tdRegistry.addTD(
        addTDArgs.tdQuote,
        qeId,
        addTDArgs.x,
        addTDArgs.y,
        addTDArgs.authenticationData,
        addTDArgs.r,
        addTDArgs.s);
    const receipt = await tx.wait();
    const tdId = (<EventLog>receipt?.logs[0]).args[0];
    console.log(`TD added with id: ${tdId}`);
    return tdId;
}

function base64ToHexBytes(base64: string): string {
    const buf = Buffer.from(base64, 'base64');
    return "0x" + buf.toString('hex');
}

function base64ToBigInt(base64: string): bigint {
    const buf = Buffer.from(base64, 'base64');
    let hex = buf.toString('hex');
    return BigInt('0x' + hex);
}

function intToHexBytes(value: number, bytesCount: number): string {
    if (!Number.isInteger(value) || value < 0) {
        throw new Error("Value must be a non-negative integer");
    }

    const max = 2 ** (8 * bytesCount);
    if (value >= max) {
        throw new Error(`Value ${value} does not fit in ${bytesCount} bytes`);
    }

    const bytes = new Uint8Array(bytesCount);
    for (let i = 0; i < bytesCount; i++) {
        bytes[i] = value & 0xff;
        value >>= 8;
    }

    return "0x" + Buffer.from(bytes).toString('hex');
}

function parsePemCert(pem: string): CertificateData {
    function pemToArrayBuffer(pem: string): ArrayBuffer {
        const base64 = pem.replace(/-----(BEGIN|END) CERTIFICATE-----/g, "").replace(/\s+/g, "");
        const buffer = Buffer.from(base64, "base64");
        return buffer.buffer.slice(buffer.byteOffset, buffer.byteOffset + buffer.byteLength);
    }

    function parseTbsCertificate(tbsCertificate: asn1js.Sequence): {
        serial: bigint,
        notBefore: string,
        notAfter: string,
        extensions: string,
        x: bigint,
        y: bigint,
        authority: string
    } {
        function parseValidity(validity: asn1js.Sequence): { notBefore: string, notAfter: string } {
            function parseUTCTime(utctime: asn1js.UTCTime): string {
                return "0x" + Buffer.from(utctime.valueBlock.valueHexView).toString('hex');
            }

            const notBefore = parseUTCTime(validity.valueBlock.value[0] as asn1js.UTCTime);
            const notAfter = parseUTCTime(validity.valueBlock.value[1] as asn1js.UTCTime);
            return { notBefore, notAfter };
        }

        function parsePublicKey(publicKey: asn1js.Sequence): { x: bigint, y: bigint } {
            const publicKeyBlock = publicKey.valueBlock.value[1] as asn1js.BitString;
            const value = publicKeyBlock.valueBlock.valueHexView;
            const x = BigInt("0x" + Buffer.from(value.slice(1, 33)).toString('hex'));
            const y = BigInt("0x" + Buffer.from(value.slice(33, 65)).toString('hex'));
            return { x, y };
        }

        function parseExtensions(extensions: asn1js.Constructed): string {
            return "0x" + Buffer.from(extensions.valueBlock.value[0].valueBeforeDecodeView).toString('hex');
        }

        function parseExtensionItem(extensionItem: asn1js.Sequence): { id: string, value: Uint8Array } {
            const extensionItemId = extensionItem.valueBlock.value[0] as asn1js.ObjectIdentifier;
            const extensionItemValue = extensionItem.valueBlock.value.length == 2
                ? extensionItem.valueBlock.value[1] as asn1js.OctetString
                : extensionItem.valueBlock.value[2] as asn1js.OctetString;
            return { id: extensionItemId.valueBlock.toString(), value: extensionItemValue.valueBlock.valueHexView };
        }

        function parseAuthority(extensions: asn1js.Constructed): string {
            const extensionSequence = extensions.valueBlock.value[0] as asn1js.Sequence;
            const extensionItems = extensionSequence.valueBlock.value;

            const authorityKeyIdentifier = extensionItems
                .map(item => parseExtensionItem(item as asn1js.Sequence))
                .find(item => item.id == "2.5.29.35");

            if (!authorityKeyIdentifier) {
                return "";
            }

            const authorityKeyIdentifierSequence = asn1js.fromBER(Buffer.from(authorityKeyIdentifier.value)).result as asn1js.Sequence;
            const authorityKeyIdentifierValue = authorityKeyIdentifierSequence.valueBlock.value[0] as asn1js.Primitive;

            return "0x" + Buffer.from(authorityKeyIdentifierValue.valueBlock.valueHexView).toString('hex');
        }

        const serial = (tbsCertificate.valueBlock.value[1] as asn1js.Integer).toBigInt();
        const { notBefore, notAfter } = parseValidity(tbsCertificate.valueBlock.value[4] as asn1js.Sequence);
        const { x, y } = parsePublicKey(tbsCertificate.valueBlock.value[6] as asn1js.Sequence);

        const extensionsBlock = tbsCertificate.valueBlock.value.find(block => block.idBlock.tagClass == 3
            && block.idBlock.tagNumber == 3
            && block.idBlock.isConstructed);
        const extensions = parseExtensions(extensionsBlock as asn1js.Constructed);
        const authority = parseAuthority(extensionsBlock as asn1js.Constructed);
        return { serial, notBefore, notAfter, extensions, x, y, authority };
    }

    function parseSignature(signature: asn1js.BitString): { r: bigint, s: bigint } {
        const signatureSequence = signature.valueBlock.value[0] as asn1js.Sequence;
        const r = (signatureSequence.valueBlock.value[0] as asn1js.Integer).toBigInt();
        const s = (signatureSequence.valueBlock.value[1] as asn1js.Integer).toBigInt();
        return { r, s };
    }

    const der = pemToArrayBuffer(pem);

    const certAsn1 = asn1js.fromBER(der);
    if (certAsn1.offset === -1 || !(certAsn1.result instanceof asn1js.Sequence)) {
        throw new Error("Failed to parse certificate");
    }

    const tbsCertificate = certAsn1.result.valueBlock.value[0];
    const signature = certAsn1.result.valueBlock.value[2];

    return {
        ...parseTbsCertificate(tbsCertificate as asn1js.Sequence),
        ...parseSignature(signature as asn1js.BitString)
    };
}

function calculateTDId(tdQuote: TDQuoteStruct): bigint {
    const types = ["(bytes20,bytes16,bytes,bytes,bytes8,bytes8,bytes8,bytes,bytes,bytes,bytes,bytes,bytes,bytes,bytes,bytes32,bytes32)"];

    const values = [[
        tdQuote.USER_DATA,
        tdQuote.TEE_TCB_SVN,
        tdQuote.MRSEAM,
        tdQuote.MRSIGNERSEAM,
        tdQuote.SEAMATTRIBUTES,
        tdQuote.TDATTRIBUTES,
        tdQuote.XFAM,
        tdQuote.MRTD,
        tdQuote.MRCONFIGID,
        tdQuote.MROWNER,
        tdQuote.MROWNERCONFIG,
        tdQuote.RTMR0,
        tdQuote.RTMR1,
        tdQuote.RTMR2,
        tdQuote.RTMR3,
        tdQuote.REPORT_DATA1,
        tdQuote.REPORT_DATA2
    ]];

    const encoded = ethers.AbiCoder.defaultAbiCoder().encode(types, values);
    const hash = ethers.keccak256(encoded);
    return BigInt(hash);
}

async function isTDRegistered(tdRegistry: ITrustDomainRegistryExtended, tdId: bigint): Promise<boolean> {
    const td = await tdRegistry.getTD(tdId);
    return BigInt(td.REPORT_DATA1) != 0n;
}

if (require.main === module) {
    let jsonData = '';
    process.stdin.on('data', chunk => {
        jsonData += chunk;
    });
    process.stdin.on('end', () => {
        const quoteData = JSON.parse(jsonData);
        run(quexConfig[env.network.name], quoteData).catch(console.error);
    });
}

export { run };