import {expect} from "chai";
import "@nomicfoundation/hardhat-ethers";
import {V1FeedRegistry, V1TrustDomainRegistry} from "../typechain";
import {ContractHelpers} from "./contract_helpers";
import {FeedStruct} from "../typechain/interfaces/IV1FeedRegistry";
import * as fs from "node:fs";
import * as path from "node:path";
import {SnapshotRestorer, takeSnapshot} from "@nomicfoundation/hardhat-toolbox/network-helpers";

describe("FeedRegistry", function () {
    let trustDomainRegistry: V1TrustDomainRegistry;
    let feedRegistry: V1FeedRegistry;
    let snapshot: SnapshotRestorer;

    const testDataDirectory = "test/testdata/feeds";
    const testCases: [string, string, FeedStruct][] = fs.readdirSync(testDataDirectory)
        .map(fileName => path.join(testDataDirectory, fileName))
        .map(filePath => fs.readFileSync(filePath, 'utf-8'))
        .map(content => JSON.parse(content))
        .map(json => [json["feedId"], json["description"], json["feed"]]);

    before(async function () {
        trustDomainRegistry = await ContractHelpers.TrustDomainRegistry.createConfigured();
        feedRegistry = await ContractHelpers.FeedRegistry.createConfigured(trustDomainRegistry);
        snapshot = await takeSnapshot();
    })

    afterEach(async () => {
        await snapshot.restore();
    })

    describe("Generate correct feed id", () => {
        for (const [expectedFeedId, description, feed] of testCases) {
            it(description, async function () {
                const feedId = await ContractHelpers.FeedRegistry.createFeed(feedRegistry, feed);
                expect(feedId).to.eq(expectedFeedId);
            });
        }
    });

    describe("Received feed is equal to created one", () => {
        for (const [, description, feed] of testCases) {
            it(description, async function () {
                const feedId = await ContractHelpers.FeedRegistry.createFeed(feedRegistry, feed);
                const resultOutput = await feedRegistry.getFeed(feedId);
                const resultFeed = ContractHelpers.FeedRegistry.Converter.feedOutputToStruct(resultOutput[1]);
                expect(resultFeed).to.eql(feed);
            });
        }
    });

    describe("Receive zero tdId if patch is empty and non-zero otherwise", () => {
        for (const [, description, feed] of testCases) {
            it(description, async function () {
                const feedId = await ContractHelpers.FeedRegistry.createFeed(feedRegistry, feed);
                const resultOutput = await feedRegistry.getFeed(feedId);
                expect(resultOutput[0]).to.eq(hasPatch(feed) ? 1 : 0);
            });
        }
    });

    describe("Do not allow to create patch if TD is not allowed", () => {
        for (const [, description, feed] of testCases.filter(x => hasPatch(x[2]))) {
            it(description, async function () {
                const owner =await ContractHelpers.getOwner();
                await trustDomainRegistry
                    .connect(owner)
                    .disableTD(1);
                await expect(feedRegistry
                    .connect(await ContractHelpers.getOwner())
                    .addPrivatePatch(1, feed.patch))
                    .to.be.revertedWith("Trust Domain is not allowed to use");
            })
        }
    });

    function hasPatch(feed: FeedStruct) {
        return feed.patch.pathSuffix != "0x"
            || feed.patch.headers.length != 0
            || feed.patch.parameters.length != 0
            || feed.patch.body != "0x";
    }
});