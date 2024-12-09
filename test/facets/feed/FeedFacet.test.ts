import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import {
    FeedFacet__factory,
    FeedFacetInitializer__factory,
    P256Verifier__factory,
    QuexDiamond,
    QuexDiamond__factory,
    TrustDomainFacet__factory,
    TrustDomainFacetInitializer__factory
} from "../../../typechain";
import { expect } from "chai";

describe('::FeedFacet', () => {
    let owner: SignerWithAddress;
    let nonOwner: SignerWithAddress;

    let diamond: QuexDiamond;

    before(async () => {
        [owner, nonOwner] = await ethers.getSigners();
    });

    beforeEach(async () => {
        const deployer = owner;

        const p256Verifier = await new P256Verifier__factory(deployer).deploy();
        await p256Verifier.waitForDeployment();

        diamond = await new QuexDiamond__factory(deployer).deploy();

        // deploy TrustDomainFacet
        const trustDomainFacet = await new TrustDomainFacet__factory(deployer).deploy();
        await trustDomainFacet.waitForDeployment();

        const trustDomainFacetInitializer = await new TrustDomainFacetInitializer__factory(deployer).deploy();
        await trustDomainFacetInitializer.waitForDeployment();
        let calldata = trustDomainFacetInitializer.interface.encodeFunctionData("init", [await p256Verifier.getAddress()]);

        const tdFacetCuts = [
            {
                target: await trustDomainFacet.getAddress(),
                action: 0,
                selectors: [ // todo: think how do it better?
                    trustDomainFacet.interface.getFunction("addRootKey").selector,
                    trustDomainFacet.interface.getFunction("getRootKey").selector,
                    trustDomainFacet.interface.getFunction("addPlatformCAKey").selector,
                    trustDomainFacet.interface.getFunction("addPCK").selector
                ]
            }
        ];

        await (await diamond.diamondCut(tdFacetCuts, await trustDomainFacetInitializer.getAddress(), calldata)).wait();

        // deploy FeedFacet
        const feedFacet = await new FeedFacet__factory(deployer).deploy();
        await feedFacet.waitForDeployment();

        const feedFacetInitializer = await new FeedFacetInitializer__factory(deployer).deploy();
        await feedFacetInitializer.waitForDeployment();
        calldata = feedFacetInitializer.interface.encodeFunctionData("init");

        const feedFacetCut = [
            {
                target: await feedFacet.getAddress(),
                action: 0,
                selectors: [ // todo:
                    feedFacet.interface.getFunction("getFeed").selector,
                    feedFacet.interface.getFunction("addRequest").selector,
                ]
            }
        ];

        await (await diamond.diamondCut(feedFacetCut, await feedFacetInitializer.getAddress(), calldata)).wait();

        // testObject = ITrustDomainRegistryExtended__factory.connect(await diamond.getAddress(), diamond.runner);
    });

    describe("::FeedFacet", () => {
        describe("#supportsInterface", () => {
            it("returns true for IFeedRegistry", async () => {
                expect(await diamond.supportsInterface("0xb40cc701")) // todo:
                    .to.be.true;
            });
        })
    })

})