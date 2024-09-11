const { expect } = require("chai");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("Full contract call chain", function () {
  it("Checking Quote Contract", async function () {
      const [owner] = await ethers.getSigners();

      const root_CA_key = {
          x: BigInt("0x0ba9c4c0c0c86193a3fe23d6b02cda10a8bbd4e88e48b4458561a36e705525f5"),
          y: BigInt("0x67918e2edc88e40d860bd0cc4ee26aacc988e505a953558c453f6b0904ae7394"),
          not_before: "0x3138303532313130343531305a",
          not_after: "0x3439313233313233353935395a"
      };

      const platform_CA_cert = {
          x: BigInt("24030003042588091771170974992323049441734798737906192722609658704857607787826"),
          y: BigInt("106254777459282516381561500528085635876136725707838022931959366032360701572062"),
          serial: BigInt("0x956f5dcdbd1be1e94049c9d4f433ce01570bde54"),
          not_before: "0x3138303532313130353031305a",
          not_after: "0x3333303532313130353031305a",
          extensions: "0x3081b8301f0603551d2304183016801422650cd65a9d3489f383b49552bf501b392706ac30520603551d1f044b30493047a045a043864168747470733a2f2f6365727469666963617465732e7472757374656473657276696365732e696e74656c2e636f6d2f496e74656c534758526f6f7443412e646572301d0603551d0e04160414956f5dcdbd1be1e94049c9d4f433ce01570bde54300e0603551d0f0101ff04040302010630120603551d130101ff040830060101ff020100",
          r: BigInt('42866170568685111900057008158509843856138296930751925740913709471306297805719'),
          s: BigInt('17237064055611587912602576747291700467597514190097038271137615530927947838334')
      };

      const processor_PCK_cert = {
          x: BigInt("0x99158f75763e8fc5e1dab9e542cb410e94decda1e46fdfbd57d996a7086c5731"),
          y: BigInt("0xb77c15cb4d3d7ef849bc170c67ba18a2f3cce1c723477a0bb52bd1af274bcb8f"),
          serial: BigInt("0xe1d36308908c642b4e39a77dfd2c18a8cf4811"),
          not_before: "0x3234303831353137303031395a",
          not_after: "0x3331303831353137303031395a",
          extensions: "0x30820308301f0603551d23041830168014956f5dcdbd1be1e94049c9d4f433ce01570bde54306b0603551d1f046430623060a05ea05c865a68747470733a2f2f6170692e7472757374656473657276696365732e696e74656c2e636f6d2f7367782f63657274696669636174696f6e2f76342f70636b63726c3f63613d706c6174666f726d26656e636f64696e673d646572301d0603551d0e041604143e4c15958d7554ad930524d9da6600305683c508300e0603551d0f0101ff0404030206c0300c0603551d130101ff040230003082023906092a864886f84d010d010482022a30820226301e060a2a864886f84d010d010104106ca004e799459e298c07ccd7af00c24e30820163060a2a864886f84d010d0102308201533010060b2a864886f84d010d0102010201023010060b2a864886f84d010d0102020201023010060b2a864886f84d010d0102030201023010060b2a864886f84d010d0102040201023010060b2a864886f84d010d0102050201033010060b2a864886f84d010d0102060201013010060b2a864886f84d010d0102070201003010060b2a864886f84d010d0102080201033010060b2a864886f84d010d0102090201003010060b2a864886f84d010d01020a0201003010060b2a864886f84d010d01020b0201003010060b2a864886f84d010d01020c0201003010060b2a864886f84d010d01020d0201003010060b2a864886f84d010d01020e0201003010060b2a864886f84d010d01020f0201003010060b2a864886f84d010d0102100201003010060b2a864886f84d010d01021102010b301f060b2a864886f84d010d0102120410020202020301000300000000000000003010060a2a864886f84d010d0103040200003014060a2a864886f84d010d01040406b0c06f000000300f060a2a864886f84d010d01050a0101301e060a2a864886f84d010d010604103aac4e3ec60fbaf6933812a1d21169a33044060a2a864886f84d010d010730363010060b2a864886f84d010d0107010101ff3010060b2a864886f84d010d0107020101ff3010060b2a864886f84d010d0107030101ff",
          authority: BigInt("0x956f5dcdbd1be1e94049c9d4f433ce01570bde54"),
          r: BigInt("0x4AED5C07C590310B27F53E021634CB8B63E2B084DFFEDCF725E0D1675D6C9479"),
          s: BigInt("0xEF8A50030D245365B227720F45AC2E11D61AE52A32C3AD57AABA0A051ABE9578")
      };

      const qe_report_data = {
          CPUSVN: "0x0202191b03ff00060000000000000000",
          MISCSELECT: "0x00000000",
          MRENCLAVE: "0xe5a3a7b5d830c2953b98534c6c59a3a34fdc34e933f7f5898f0a85cf08846bca",
          attributes: "0x1500000000000000e700000000000000",
          MRSIGNER: "0xdc9e2a7c6f948f17474e34a7fc43ed030f7c1563f1babddf6340c82e0e54a8c5",
          ISVProdID: "0x0200",
          ISVSVN: "0x0600",
          REPORT_DATA1: "0x4cb92b5fa2a172c969957d91651195ab0f8681a33194f3792736972cefbc550c",
          REPORT_DATA2: "0x0000000000000000000000000000000000000000000000000000000000000000"
      };

      const qe_report_signature = {
          //r: BigInt("0x2e109f9b089c179e17cc891c07ed6977c7e9181fd65ee93213960a6a0651e088"),
          //s: BigInt("0x2eac7101546b5b8dbc36b9b52c2dd903f2ca4217658d1a102ae72cf3de16f942")
          r: BigInt("0x69f09715ad7907a29525c9fbeb5dab944e382e2202e0e688d25c36066cb7f6e7"),
          s: BigInt("0x76cc97e3f4054e218a9696a4710987e6d0b17f64acadf8efb1c3c602dcfdeb7e")
      };
      const attestation_key = {
          x: BigInt("0x0055e0d6cd42264d249623af0ce703cc5ed2c2c3e36d3e2a29c3432de33399fd"),
          y: BigInt("0xd1f21d5e3dce84530b384c202770f718219b435ef437b99eccb6a091af20cdfe")
      };
      const qe_authentication_data = "0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f";

      const quote_signature = {
          //r: BigInt("0x918a13424b6e7c8b2f4e7f028a2842ff930a664a1602ffb30f16cbabf8479897"),
          //s: BigInt("0x83bc721844f07c61263b819a88c489d52a37d7e55b55d018040cdecea231791d")
          r: BigInt("0x509a7c8285d698c12c5027234155d00f649b9b4447187794739e811575a2bd84"),
          s: BigInt("0x85761a1507f29fe111137a3406daa91b587316e761c2116c3a2ff423f86bfc43")
      };


      const td_quote = {
          USER_DATA: "0xfaaf591cd3e1ff05ac1399441935520400000000",
          TEE_TCB_SVN: "0x05010200000000000000000000000000",
          MRSEAM: "0x1cc6a17ab799e9a693fac7536be61c12ee1e0fabada82d0c999e08ccee2aa86de77b0870f558c570e7ffe55d6d47fa04",
          MRSIGNERSEAM: "0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
          SEAMATTRIBUTES: "0x0000000000000000",
          TDATTRIBUTES: "0x0000001000000000",
          XFAM: "0xe702060000000000",
          MRTD: "0x91eb2b44d141d4ece09f0c75c2c53d247a3c68edd7fafe8a3520c942a604a407de03ae6dc5f87f27428b2538873118b7",
          MRCONFIGD: "0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
          MROWNER: "0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
          MROWNERCONFIG: "0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
          RTMR0: "0xaec1f04eefc2f71f91196632228f7d2f310ce80c261c13400cea5687c5c7e2cd4d622fa7efba10c92ccbde5c385803a3",
          RTMR1: "0xa89b15e9d123b5c034bc5bdd6b37c3a442018befa6a4ff5c059c7bb8adc802b594109baed5ec28b51f575ec57d732f56",
          RTMR2: "0x3479bc93f86f147e1eddfdd76d08a1cd51892547c056153f07e52e663a08692207f48597d0cd9c63ae86ac7939a4fe87",
          RTMR3: "0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
          REPORT_DATA1: "0x000000000000000000000000ca614cd12d3b9515610c4d8b901de4b5641be508",
          REPORT_DATA2: "0x0000000000000000000000000000000000000000000000000000000000000000"
      };

      const dataItems = [
          {'data': {'timestamp': 1725013586, 'value': 5955810}, 'signature': {'r': '0x3cde7641aa14b17f89587d83fe79f941f1c88c23fe3c44724b5aeb7ba6275ad6', 's': '0x596459a0ce726e2549c8c76db19ee170f2a4d0f080876298fecd9a29b90b9e64', 'v': 28}},
          {'data': {'timestamp': 1725013665, 'value': 5958800}, 'signature': {'r': '0x788d7fceaf5bd6e90ee94308b995b3b372d933ec608923618da0cce1abf1e9a0', 's': '0x09ee6b6aa4fd0cd3896f63627a86665b01b207956fc4bb036d345bd636459382', 'v': 27}},
          {'data': {'timestamp': 1725013689, 'value': 5958200}, 'signature': {'r': '0xdace6d568240d9073b44f218180b908736167aa2c493fc87d156eb395545ef57', 's': '0x7706d652f9bed221fd886f7271385393d7f55a38198033761e0ffb78e5d08f9f', 'v': 27}}
      ];

      const p256Verifier = await ethers.deployContract("P256Verifier");

      const certVerifierFactory = await ethers.getContractFactory("V1CertificateVerifier");
      const certVerifier = await certVerifierFactory.deploy(owner.address, await p256Verifier.getAddress());

      const quoteVerifierFactory = await ethers.getContractFactory("V1QuoteVerifier");
      const quoteVerifier = await quoteVerifierFactory.deploy(await p256Verifier.getAddress(), await certVerifier.getAddress());

      const logPoliciesFactory = await ethers.getContractFactory("V1LogPolicies");
      const logPolicies = await logPoliciesFactory.deploy(owner.address);

      const signersRegistryFactory = await ethers.getContractFactory("V1SignersRegistry");
      const signersRegistry = await signersRegistryFactory.deploy(await quoteVerifier.getAddress());

      const logFactory = await ethers.getContractFactory("V1Log");
      const logContract = await logFactory.deploy(owner.address, await logPolicies.getAddress(), await signersRegistry.getAddress());

      const res1 = await certVerifier.connect(owner).addRootKey(
          root_CA_key
      );

      const res2 = await certVerifier.connect(owner).addPlatformCAKey(
          platform_CA_cert.x,
          platform_CA_cert.y,
          platform_CA_cert.serial,
          platform_CA_cert.not_before,
          platform_CA_cert.extensions,
          platform_CA_cert.r,
          platform_CA_cert.s,
      );

      const res3 = await certVerifier.connect(owner).addPCK(
          processor_PCK_cert.x,
          processor_PCK_cert.y,
          processor_PCK_cert.serial,
          processor_PCK_cert.not_before,
          processor_PCK_cert.not_after,
          processor_PCK_cert.extensions,
          processor_PCK_cert.authority,
          processor_PCK_cert.r,
          processor_PCK_cert.s
      );
      const res4 = await quoteVerifier.connect(owner).addQE(
          qe_report_data,
          platform_CA_cert.serial,
          processor_PCK_cert.serial,
          qe_report_signature.r,
          qe_report_signature.s
      );

      const res5 = await quoteVerifier.connect(owner).addTD(
          td_quote, 
          1,
          attestation_key.x,
          attestation_key.y,
          qe_authentication_data,
          quote_signature.r,
          quote_signature.s
      );

      const res6 = await signersRegistry.connect(owner).addSigner(1);

      const res7 = await logPolicies.connect(owner).addTD(1);

      for (let i = 0; i < dataItems.length; i++) {
          res8 = await logContract.connect(owner).pushData(
              dataItems[i].data,
              1,
              dataItems[i].signature.v,
              dataItems[i].signature.r,
              dataItems[i].signature.s,
          );
      }
  });
});
