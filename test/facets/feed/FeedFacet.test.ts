import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import {
    FeedFacet,
    IFeedRegistry,
    IFeedRegistry__factory,
    QuexDiamond,
    QuexDiamond__factory,
} from "../../../typechain";
import { expect } from "chai";
import { ContractHelpers } from "../contract_helpers";
import { SnapshotRestorer, takeSnapshot } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { FeedStruct } from "../../../typechain/interfaces/IV1FeedRegistry";
import fs from "node:fs";
import path from "node:path";

describe("::FeedFacet", () => {
    let owner: SignerWithAddress;
    let nonOwner: SignerWithAddress;

    let diamond: QuexDiamond;
    let feedFacet: FeedFacet;

    let snapshot: SnapshotRestorer;

    before(async () => {
        [owner, nonOwner] = await ethers.getSigners();
    });

    beforeEach(async () => {
        diamond = await new QuexDiamond__factory(owner).deploy();
        await ContractHelpers.TrustDomainFacet.createAndAddToDiamond(diamond, owner);
        feedFacet = await ContractHelpers.FeedFacet.createAndAddToDiamond(diamond, owner);
        snapshot = await takeSnapshot();
    });

    afterEach(async () => {
        await snapshot.restore();
    });

    describe("::FeedFacet", () => {
        describe("::FeedRegistryFacet", () => {
            let testObject: IFeedRegistry;

            const testDataDirectory = "test/testdata/feeds";
            const testCases: [string, string, FeedStruct][] = fs.readdirSync(testDataDirectory)
                .map(fileName => path.join(testDataDirectory, fileName))
                .map(filePath => fs.readFileSync(filePath, 'utf-8'))
                .map(content => JSON.parse(content))
                .map(json => [json["feedId"], json["description"], json["feed"]]);

            beforeEach(async () => {
                testObject = IFeedRegistry__factory.connect(await diamond.getAddress(), diamond.runner);
            });

            describe("#addFeed", () => {
                describe("generates correct feed id", () => {
                    for (const [expectedFeedId, description, feed] of testCases) {
                        it(description, async function () {
                            const feedId = await ContractHelpers.FeedFacet.FeedRegistry.createFeed(testObject, feed);
                            expect(feedId).to.be.eq(expectedFeedId);
                        });
                    }
                });
            });

            describe("#getFeed", () => {
                describe("receives feed is equal to created one", () => {
                    for (const [, description, feed] of testCases) {
                        it(description, async function () {
                            const feedId = await ContractHelpers.FeedFacet.FeedRegistry.createFeed(testObject, feed);
                            const resultOutput = await testObject.getFeed(feedId);
                            const resultFeed = ContractHelpers.FeedFacet.FeedRegistry.Converter.feedOutputToStruct(resultOutput[1]);
                            expect(resultFeed).to.be.eql(feed);
                        });
                    }
                });

                describe("receives zero tdAddress if patch is empty and non-zero otherwise", () => {
                    for (const [, description, feed] of testCases) {
                        it(description, async function () {
                            const address = await (await ethers.getSigners())[10].getAddress();
                            const emptyAddress = "0x0000000000000000000000000000000000000000";
                            const feedId = await ContractHelpers.FeedFacet.FeedRegistry.createFeed(testObject, feed, address);
                            const resultOutput = await testObject.getFeed(feedId);
                            expect(resultOutput[0]).to.be.eq(hasPatch(feed) ? address : emptyAddress);
                        });
                    }
                });

                function hasPatch(feed: FeedStruct) {
                    return feed.patch.pathSuffix != "0x"
                        || feed.patch.headers.length != 0
                        || feed.patch.parameters.length != 0
                        || feed.patch.body != "0x";
                }
            });

            describe("#addRequest", () => {
                describe("reverts if", () => {
                    it("host is empty", async () => {
                        const request = structuredClone(testCases[0][2].request);
                        request.host = "";
                        await expect(testObject
                            .addRequest(request))
                            .to.be.rejectedWith("Host is required");

                    })
                });
            });

            describe("#addJqFilter", () => {
                describe("reverts if", () => {
                    it("filter is empty", async () => {
                        await expect(testObject
                            .addJqFilter(""))
                            .to.be.rejectedWith("Filter couldn't be empty");})
                });
            });

            describe("#addResponseSchema", () => {
                describe("reverts if", () => {
                    it("schema is empty", async () => {
                        await expect(testObject
                            .addResponseSchema(""))
                            .to.be.rejectedWith("Schema couldn't be empty");})
                });
            });
        });

        describe("::FeedRequestRegistryFacet", () => {
            // todo
        });

        describe("::FeedTrustDomainPolicyFacet", () => {
            // todo
        });
    });

});