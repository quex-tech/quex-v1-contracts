import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import {
    ITrustDomainRegistryExtended, ITrustDomainRegistryExtended__factory, P256Verifier__factory,
    QuexDiamond,
    QuexDiamond__factory, TrustDomainFacet,
    TrustDomainFacet__factory, TrustDomainFacetInitializer__factory
} from "../../typechain";
import { ethers } from "hardhat";
import { ECKeyStruct } from "../../typechain/contracts/facets/trust_domain/TrustDomainFacet";
import { expect } from "chai";

describe("TrustDomainFacet", () => {
    let owner: SignerWithAddress;
    let nonOwner: SignerWithAddress;

    let diamond: QuexDiamond;
    let trustDomainFacet: TrustDomainFacet;
    let testObject: ITrustDomainRegistryExtended;

    const rootKey: ECKeyStruct = {
        x: BigInt("0x0ba9c4c0c0c86193a3fe23d6b02cda10a8bbd4e88e48b4458561a36e705525f5"),
        y: BigInt("0x67918e2edc88e40d860bd0cc4ee26aacc988e505a953558c453f6b0904ae7394"),
        notBefore: BigInt("0x3138303532313130343531305a"), // todo: check it later
        notAfter: BigInt("0x3439313233313233353935395a") // todo: check it later
    };

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

    before(async () => {
        [owner, nonOwner] = await ethers.getSigners();
    });

    beforeEach(async () => {
        const deployer = owner;

        const p256Verifier = await new P256Verifier__factory(deployer).deploy();
        await p256Verifier.waitForDeployment();

        diamond = await new QuexDiamond__factory(deployer).deploy();
        trustDomainFacet = await new TrustDomainFacet__factory(deployer).deploy();
        await trustDomainFacet.waitForDeployment();

        const trustDomainFacetInitializer = await new TrustDomainFacetInitializer__factory(deployer).deploy();
        await trustDomainFacetInitializer.waitForDeployment();
        const calldata = trustDomainFacetInitializer.interface.encodeFunctionData("init", [await p256Verifier.getAddress()]);

        const facetCuts = [
            {
                target: await trustDomainFacet.getAddress(),
                action: 0,
                selectors: [
                    trustDomainFacet.interface.getFunction("addRootKey").selector,
                    trustDomainFacet.interface.getFunction("getRootKey").selector,
                    trustDomainFacet.interface.getFunction("addPlatformCAKey").selector,
                    trustDomainFacet.interface.getFunction("addPCK").selector
                ]
            }
        ];

        await (await diamond.diamondCut(facetCuts, await trustDomainFacetInitializer.getAddress(), calldata)).wait();

        testObject = ITrustDomainRegistryExtended__factory.connect(await diamond.getAddress(), diamond.runner);
    });

    describe("#addRootKey", () => {
        it("adds root key", async () => {
            await expect(testObject.connect(owner).addRootKey(rootKey))
                .not.to.be.reverted;

            const rootKeyResult = await testObject.getRootKey();
            expect(rootKeyResult.x).to.equal(rootKey.x);
            expect(rootKeyResult.y).to.equal(rootKey.y);
            expect(rootKeyResult.notBefore).to.equal(rootKey.notBefore);
            expect(rootKeyResult.notAfter).to.equal(rootKey.notAfter);
        });

        describe("revert if", () => {
            it("sender is not owner", async () => {
                await expect(testObject.connect(nonOwner).addRootKey(rootKey))
                    .to.be.revertedWithCustomError(diamond, "Ownable__NotOwner");
            });
        });
    });

    describe("#addPlatformCAKey", () => {
        beforeEach(async () => {
            await testObject.connect(owner).addRootKey(rootKey);
        });

        it("adds platform CA key", async () => {
            await expect(testObject.connect(owner).addPlatformCAKey(
                platformCaCert.x,
                platformCaCert.y,
                platformCaCert.serial,
                platformCaCert.notBefore,
                platformCaCert.extensions,
                platformCaCert.r,
                platformCaCert.s
            )).not.to.be.reverted;

            // todo: call getPlatformCA and check
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
                        wrongPlatformCaCert.extensions,
                        wrongPlatformCaCert.r,
                        wrongPlatformCaCert.s
                    ))
                    .to.be.revertedWithCustomError(trustDomainFacet, "InvalidPlatformCertificate");
            });
        });
    });

    describe("#addPCK", async () => {
        beforeEach(async () => {
            await testObject.connect(owner).addRootKey(rootKey);
            await testObject.connect(nonOwner).addPlatformCAKey(
                platformCaCert.x,
                platformCaCert.y,
                platformCaCert.serial,
                platformCaCert.notBefore,
                platformCaCert.extensions,
                platformCaCert.r,
                platformCaCert.s
            );
        });

        it("adds PCK", async () => {
            // todo
        })
    });
});