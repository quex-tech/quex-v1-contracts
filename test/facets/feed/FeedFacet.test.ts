import { ethers } from "hardhat";
import { type HardhatEthersSigner, SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import {
    FeedFacet,
    IFeedRegistry,
    IFeedRegistry__factory,
    IFeedRequestRegistryExtended,
    IFeedRequestRegistryExtended__factory,
    IFeedTrustDomainPolicyExtended__factory,
    QuexDiamond,
    QuexDiamond__factory,
    TestQuexResponseProcessor
} from "../../../typechain";
import { expect } from "chai";
import { ContractHelpers } from "../contract_helpers";
import { reset, SnapshotRestorer, takeSnapshot, time } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { FeedStruct } from "../../../typechain/interfaces/IV1FeedRegistry";
import fs from "node:fs";
import path from "node:path";
import { RequestResultStruct } from "../../../typechain/contracts/facets/feed/FeedFacet";

describe("::FeedFacet", () => {
    let owner: SignerWithAddress;
    let nonOwner: SignerWithAddress;

    let diamond: QuexDiamond;
    let feedFacet: FeedFacet;

    let snapshot: SnapshotRestorer;

    before(async () => {
        await reset();
        [owner, nonOwner] = await ethers.getSigners();

        diamond = await new QuexDiamond__factory(owner).deploy();
        await ContractHelpers.TrustDomainFacet.createAndAddToDiamond(diamond, owner);
        await ContractHelpers.TrustDomainFacet.configureFully(diamond, owner);
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
                .map(filePath => fs.readFileSync(filePath, "utf-8"))
                .map(content => JSON.parse(content))
                .map(json => [json["feedId"], json["description"], json["feed"]]);

            beforeEach(async () => {
                testObject = IFeedRegistry__factory.connect(await diamond.getAddress(), diamond.runner);
            });

            describe("#addFeed", () => {
                describe("generates correct feed id", () => {
                    for (const [expectedFeedId, description, feed] of testCases) {
                        it(description, async function() {
                            const feedId = await ContractHelpers.FeedFacet.FeedRegistry.createFeed(diamond, feed);
                            expect(feedId).to.be.eq(expectedFeedId);
                        });
                    }
                });
            });

            describe("#getFeed", () => {
                describe("receives feed is equal to created one", () => {
                    for (const [, description, feed] of testCases) {
                        it(description, async function() {
                            const feedId = await ContractHelpers.FeedFacet.FeedRegistry.createFeed(diamond, feed);
                            const resultOutput = await testObject.getFeed(feedId);
                            const resultFeed = ContractHelpers.FeedFacet.FeedRegistry.Converter.feedOutputToStruct(resultOutput[1]);
                            expect(resultFeed).to.be.eql(feed);
                        });
                    }
                });

                describe("receives zero tdAddress if patch is empty and non-zero otherwise", () => {
                    for (const [, description, feed] of testCases) {
                        it(description, async function() {
                            const address = await (await ethers.getSigners())[10].getAddress();
                            const emptyAddress = "0x0000000000000000000000000000000000000000";
                            const feedId = await ContractHelpers.FeedFacet.FeedRegistry.createFeed(diamond, feed, address);
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

                    });
                });
            });

            describe("#addJqFilter", () => {
                describe("reverts if", () => {
                    it("filter is empty", async () => {
                        await expect(testObject
                            .addJqFilter(""))
                            .to.be.rejectedWith("Filter couldn't be empty");
                    });
                });
            });

            describe("#addResponseSchema", () => {
                describe("reverts if", () => {
                    it("schema is empty", async () => {
                        await expect(testObject
                            .addResponseSchema(""))
                            .to.be.rejectedWith("Schema couldn't be empty");
                    });
                });
            });
        });

        describe("::FeedRequestRegistryFacet", () => {
            let feedId: string;
            let feedIdWithPatch: string;
            let callbackContract: TestQuexResponseProcessor;
            let callbackAddress: string;
            let callbackGoodMethod: string;
            let callbackErrorMethod: string;
            let callbackBadSignatureMethod: string;

            const response: RequestResultStruct = {
                dataItem: {
                    timestamp: 1731070829,
                    feedId: "0x494bfcfb4cc9d5c67112179ef33ab6792d60a298a1c50e6496302edfa8e9b306",
                    value: "0x00000000000000000000000000000000000000000000000000000000003ae620"
                },
                signature: {
                    r: "0xce147ddddf12bb982973dc022ca648a642f89f3a2eb49bcf80640baa0307573e",
                    s: "0x46d86b4a484891d6941748284c1be8d0599ae8282d4ce4dcb8a6b6d1ad316b55",
                    v: 28
                },
                tdAddress: ContractHelpers.TrustDomainFacet.TestData.tdAddress
            };

            const oneEther = BigInt("1000000000000000000");

            let testObject: IFeedRequestRegistryExtended;

            beforeEach(async () => {
                feedId = await ContractHelpers.FeedFacet.FeedRegistry.createFeed(diamond);
                const feedWithPatch = {
                    request: {
                        method: 0,
                        host: "www.binance.com",
                        path: "/api/v3/ticker/price",
                        headers: [],
                        parameters: [],
                        body: "0x"
                    },
                    patch: {
                        pathSuffix: "0x12",
                        headers: [],
                        parameters: [],
                        body: "0x"
                    },
                    schema: "int256",
                    filter: ".[] | select(.symbol == \"ETHBTC\") | (.price | tonumber * 100000000 | floor)"
                };
                feedIdWithPatch = await ContractHelpers.FeedFacet.FeedRegistry.createFeed(diamond, feedWithPatch);
                testObject = IFeedRequestRegistryExtended__factory.connect(await diamond.getAddress(), diamond.runner);

                callbackContract = await ContractHelpers.TestQuexResponseProcessor.deploy();
                callbackAddress = await callbackContract.getAddress();
                callbackGoodMethod = callbackContract.interface.getFunction("goodProcessor").selector;
                callbackErrorMethod = callbackContract.interface.getFunction("errorProcessor").selector;
                callbackBadSignatureMethod = callbackContract.interface.getFunction("badSignatureProcessor").selector;
            });

            describe("#sendFeedRequest", () => {
                it("charges only request price", async () => {
                    const initialBalance = await ethers.provider.getBalance(await nonOwner.getAddress());

                    const user = nonOwner;

                    const txResponse = await testObject
                        .connect(user)
                        .sendFeedRequest(feedId, callbackAddress, callbackGoodMethod, 1, { value: oneEther });
                    const requestId = await ContractHelpers.FeedFacet.RequestRegistry.getRequestId(txResponse);
                    const requestPrice = await ContractHelpers.FeedFacet.RequestRegistry.getRequestPrice(testObject, requestId);
                    const txGasFee = await ContractHelpers.getTransactionGasFee(txResponse.hash);

                    const resultBalance = await ethers.provider.getBalance(await user.getAddress());

                    expect(initialBalance - resultBalance - txGasFee).to.eq(requestPrice);
                });

                describe("reverts if", () => {
                    it("feed not found", async () => {
                        const wrongFeedId = "0xce147ddddf12bb982973dc022ca648a642f89f3a2eb49bcf80640baa0307573e";
                        await expect(
                            testObject.sendFeedRequest(wrongFeedId, callbackAddress, callbackGoodMethod, 1, { value: oneEther })
                        ).to.be.revertedWith("Feed doesn't exist");
                    });

                    it("value is insufficient", async () => {
                        await expect(
                            testObject.sendFeedRequest(feedId, callbackAddress, callbackGoodMethod, 1, { value: 1 })
                        ).to.be.revertedWith("Insufficient value sent");
                    });
                });
            });

            describe("#processResponse", () => {
                let requestId: string;
                let requestPrice: bigint;
                let relayer: HardhatEthersSigner;

                beforeEach(async () => {
                    relayer = nonOwner;
                    await IFeedTrustDomainPolicyExtended__factory.connect(await diamond.getAddress(), diamond.runner)
                        .connect(owner)
                        .allowTDForFeed(response.tdAddress);
                });

                async function prepareRequest(request: {
                    feedId?: string,
                    callbackAddress?: string,
                    callbackMethod?: string,
                    callbackGasLimit?: bigint
                }) {
                    request.feedId ??= feedId;
                    request.callbackAddress ??= callbackAddress;
                    request.callbackMethod ??= callbackGoodMethod;
                    request.callbackGasLimit ??= BigInt(1000000);

                    const txResponse = await testObject
                        .sendFeedRequest(request.feedId, request.callbackAddress, request.callbackMethod, request.callbackGasLimit, { value: oneEther });
                    requestId = await ContractHelpers.FeedFacet.RequestRegistry.getRequestId(txResponse);
                    requestPrice = await ContractHelpers.FeedFacet.RequestRegistry.getRequestPrice(testObject, requestId);
                }

                describe("pay to relayer and delete request if", () => {
                    const testCases: [string, {
                        feedId?: string,
                        callbackAddress?: string,
                        callbackMethod?: string,
                        callbackGasLimit?: bigint
                    }][] = [
                        ["everything went as expected", {}],
                        ["callback method reverts transaction", { callbackMethod: callbackErrorMethod }],
                        ["callback method has wrong signature", { callbackMethod: callbackBadSignatureMethod }],
                        ["callback method not exist", { callbackMethod: "0x00112233" }],
                        ["callback contract not exist", { callbackAddress: "0x0011223344556677889900112233445566778899" }],
                        ["callback gas limit is not enough", { callbackGasLimit: BigInt(1) }]
                    ];

                    for (const [description, prepareRequestParams] of testCases) {
                        it(description, async () => {
                            await time.setNextBlockTimestamp(response.dataItem.timestamp);
                            await prepareRequest(prepareRequestParams);

                            const initialContractBalance = await ethers.provider.getBalance(await diamond.getAddress());
                            const initialRelayerBalance = await ethers.provider.getBalance(await relayer.getAddress());

                            const txResponse = await testObject.connect(relayer).processFeedResponse(requestId, response);
                            const txGasFee = await ContractHelpers.getTransactionGasFee(txResponse.hash);

                            const resultContractBalance = await ethers.provider.getBalance(await diamond.getAddress());
                            const resultRelayerBalance = await ethers.provider.getBalance(await relayer.getAddress());

                            expect(resultContractBalance).to.eq(initialContractBalance - requestPrice);
                            expect(resultRelayerBalance).to.eq(initialRelayerBalance + requestPrice - txGasFee);
                            expect((await testObject.getFeedRequest(requestId))[0])
                                .to.be.eq("0x0000000000000000000000000000000000000000000000000000000000000000");
                        });
                    }
                });

                describe("reverts if", () => {
                    it("signature is incorrect", async () => {
                        await time.setNextBlockTimestamp(response.dataItem.timestamp);
                        await prepareRequest({});

                        const wrongResponse = structuredClone(response);
                        wrongResponse.signature.r = "0xce147ddddf12bb982973dc022ca648a642f89f3a2eb49bcf80640baa0307574e";

                        await expect(testObject.processFeedResponse(requestId, wrongResponse))
                            .to.be.revertedWith("Signature is not valid");
                    });

                    it("feedId in response and feedId in request are different", async () => {
                        await prepareRequest({});

                        const response: RequestResultStruct = {
                            dataItem: {
                                timestamp: 1731332075,
                                feedId: "0xc8439b6e40b6b50a0a840b9a7b11b6753cf41dec6f32b0f2831c3f1966f7d3b4",
                                value: "0x00000000000000000000000000000000000000000000000000000000003ae238",
                            },
                            signature: {
                                r: "0x181178ad1014935cb1ba2d538178aea19cfebc3bb782e65cd4fc8484b005d210",
                                s: "0x0079f291a2c478e381c8a9547e5344a0bd07aa7f538b3ff08e4ff58428405c94",
                                v: 28,
                            },
                            tdAddress: ContractHelpers.TrustDomainFacet.TestData.tdAddress,
                        };
                        await time.setNextBlockTimestamp(response.dataItem.timestamp);

                        await expect(testObject.processFeedResponse(requestId, response))
                            .to.be.revertedWith("Response feed id is different from request feed id");
                    });

                    it("tdId is not allowed to use", async () => {
                        await time.setNextBlockTimestamp(response.dataItem.timestamp);
                        await prepareRequest({});

                        await IFeedTrustDomainPolicyExtended__factory.connect(await diamond.getAddress(), diamond.runner)
                            .connect(owner)
                            .disallowTDForFeed(response.tdAddress);

                        await expect(testObject.processFeedResponse(requestId, response))
                            .to.be.revertedWith("Trust Domain is not allowed to use");
                    });

                    const overTimeDifference = BigInt(30 * 60 + 1); // 30 min 1 sec
                    const testCases: [string, bigint][] = [
                        ["time skew is high. Response timestamp in the future", BigInt(response.dataItem.timestamp) - overTimeDifference],
                        ["time skew is high. Response timestamp in the past", BigInt(response.dataItem.timestamp) + overTimeDifference],
                    ];

                    for (const [description, blockchainTime] of testCases) {
                        it(description, async () => {
                            // note: move blockchain time to the past to be able to set `blockchainTime`
                            // otherwise we could get an error that last block time is higher than the one we want to set
                            await time.setNextBlockTimestamp(blockchainTime - overTimeDifference);

                            await prepareRequest({});
                            await time.setNextBlockTimestamp(blockchainTime);

                            await expect(testObject.processFeedResponse(requestId, response))
                                .to.be.revertedWith("Time skew is too high");
                        });
                    }
                });
            });
        });

        describe("::FeedTrustDomainPolicyFacet", () => {
            // todo
        });
    });

});