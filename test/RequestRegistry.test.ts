import {expect} from "chai";
import "@nomicfoundation/hardhat-ethers";
import {time, reset, takeSnapshot, SnapshotRestorer} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import {TestQuexResponseProcessor, V1RequestRegistry, V1TrustDomainRegistry} from "../typechain";
import {ContractHelpers} from "./contract_helpers";
import {RequestResultStruct} from "../typechain/interfaces/IV1RequestRegistry";
import type {HardhatEthersSigner} from "@nomicfoundation/hardhat-ethers/signers";
import {ethers} from "hardhat";


describe("RequestRegistry", function () {
    let feedId: string;
    let feedIdWithPatch: string;
    let trustDomainRegistry: V1TrustDomainRegistry;
    let requestRegistry: V1RequestRegistry;
    let callbackContract: TestQuexResponseProcessor;
    let callbackAddress: string;
    let callbackGoodMethod: string;
    let callbackErrorMethod: string;
    let callbackBadSignatureMethod: string;
    let userSigner: HardhatEthersSigner;
    let snapshot: SnapshotRestorer;

    const response: RequestResultStruct = {
        dataItem: {
            timestamp: 1731070829,
            feedId: "0x494bfcfb4cc9d5c67112179ef33ab6792d60a298a1c50e6496302edfa8e9b306",
            value: "0x00000000000000000000000000000000000000000000000000000000003ae620",
        },
        signature: {
            r: "0xce147ddddf12bb982973dc022ca648a642f89f3a2eb49bcf80640baa0307573e",
            s: "0x46d86b4a484891d6941748284c1be8d0599ae8282d4ce4dcb8a6b6d1ad316b55",
            v: 28,
        },
        tdId: 1,
    };

    const oneEther = BigInt("1000000000000000000");

    before(async () => {
        await reset();
        trustDomainRegistry = await ContractHelpers.TrustDomainRegistry.createConfigured();
        const feedRegistry = await ContractHelpers.FeedRegistry.createConfigured(trustDomainRegistry);
        feedId = await ContractHelpers.FeedRegistry.createFeed(feedRegistry);
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
        feedIdWithPatch = await ContractHelpers.FeedRegistry.createFeed(feedRegistry, feedWithPatch);
        requestRegistry = await ContractHelpers.RequestRegistry.createConfigured(feedRegistry, trustDomainRegistry);
        callbackContract = await ContractHelpers.TestQuexResponseProcessor.deploy();
        callbackAddress = await callbackContract.getAddress();
        callbackGoodMethod = callbackContract.interface.getFunction("goodProcessor").selector;
        callbackErrorMethod = callbackContract.interface.getFunction("errorProcessor").selector;
        callbackBadSignatureMethod = callbackContract.interface.getFunction("badSignatureProcessor").selector;
        userSigner = await ContractHelpers.getUser();
        await time.setNextBlockTimestamp(response.dataItem.timestamp);
        snapshot = await takeSnapshot();
    });

    afterEach(async () => {
        await snapshot.restore();
    })

    describe("sendRequest", function () {
        it("charge only request price", async () => {
            const initialBalance = await ethers.provider.getBalance(await userSigner.getAddress());

            const txResponse = await requestRegistry
                .connect(userSigner)
                .sendRequest(feedId, callbackAddress, callbackGoodMethod, 1, {value: oneEther});
            const requestId = await ContractHelpers.RequestRegistry.getRequestId(txResponse);
            const requestPrice = await ContractHelpers.RequestRegistry.getRequestPrice(requestRegistry, requestId);
            const txGasFee = await ContractHelpers.getTransactionGasFee(txResponse.hash);

            const resultBalance = await ethers.provider.getBalance(await userSigner.getAddress());

            expect(initialBalance - resultBalance - txGasFee).to.eq(requestPrice);
        });

        it("revert if feed not found", async () => {
            const wrongFeedId = "0xce147ddddf12bb982973dc022ca648a642f89f3a2eb49bcf80640baa0307573e";
            await expect(
                requestRegistry
                    .connect(userSigner)
                    .sendRequest(wrongFeedId, callbackAddress, callbackGoodMethod, 1, {value: oneEther})
            ).to.be.revertedWith("Feed doesn't exist");
        });

        it("revert if value is insufficient", async () => {
            await expect(
                requestRegistry
                    .connect(userSigner)
                    .sendRequest(feedId, callbackAddress, callbackGoodMethod, 1, {value: 1})
            ).to.be.revertedWith("Insufficient value sent");
        });

        it("revert id TD is not allowed", async () => {
            await trustDomainRegistry
                .connect(await ContractHelpers.getOwner())
                .disableTD(1);
            await expect(
                requestRegistry
                    .connect(userSigner)
                    .sendRequest(feedIdWithPatch, callbackAddress, callbackGoodMethod, 1, {value: oneEther})
            ).to.be.revertedWith("Trust Domain is not allowed to use");
        });
    })

    describe("processResponse", function () {
        let requestId: string;
        let requestPrice: bigint;
        let relayerSigner: HardhatEthersSigner;

        before(async () => {
            relayerSigner = await ContractHelpers.getRelayer();
        });

        async function prepareRequest(request: {feedId?: string, callbackAddress?: string, callbackMethod?: string, callbackGasLimit?: bigint}) {
            request.feedId ??= feedId;
            request.callbackAddress ??= callbackAddress;
            request.callbackMethod ??= callbackGoodMethod;
            request.callbackGasLimit ??= BigInt(1000000);

            const txResponse = await requestRegistry
                .connect(userSigner)
                .sendRequest(request.feedId, request.callbackAddress, request.callbackMethod, request.callbackGasLimit, {value: oneEther});
            requestId = await ContractHelpers.RequestRegistry.getRequestId(txResponse);
            requestPrice = await ContractHelpers.RequestRegistry.getRequestPrice(requestRegistry, requestId);
        }

        describe("request should be deleted and relayer should be paid if", () => {
            const testCases: [string, {feedId?: string, callbackAddress?: string, callbackMethod?: string, callbackGasLimit?: bigint}][] = [
                ["everything went as expected", {}],
                ["callback method reverts transaction", {callbackMethod: callbackErrorMethod}],
                ["callback method has wrong signature", {callbackMethod: callbackBadSignatureMethod}],
                ["callback method not exist", {callbackMethod: "0x00112233"}],
                ["callback contract not exist", {callbackAddress: "0x0011223344556677889900112233445566778899"}],
                ["callback gas limit is not enough", {callbackGasLimit: BigInt(1)}]
            ];

            for (const [description, prepareRequestParams] of testCases) {
                it(description, async () => {
                    await prepareRequest(prepareRequestParams);

                    const initialContractBalance = await ethers.provider.getBalance(await requestRegistry.getAddress());
                    const initialRelayerBalance = await ethers.provider.getBalance(await relayerSigner.getAddress());

                    const txResponse = await requestRegistry.connect(relayerSigner).processResponse(requestId, response);
                    const txGasFee = await ContractHelpers.getTransactionGasFee(txResponse.hash);

                    const resultContractBalance = await ethers.provider.getBalance(await requestRegistry.getAddress());
                    const resultRelayerBalance = await ethers.provider.getBalance(await relayerSigner.getAddress());

                    expect(resultContractBalance).to.eq(initialContractBalance - requestPrice);
                    expect(resultRelayerBalance).to.eq(initialRelayerBalance + requestPrice - txGasFee);
                    expect((await requestRegistry.requests(requestId))[0])
                        .to.be.eq("0x0000000000000000000000000000000000000000000000000000000000000000");
                });
            }
        });

        describe("request shouldn't be deleted and relayer shouldn't be paid if", () => {
            it("signature is incorrect", async () => {
                await prepareRequest({});

                const wrongResponse = structuredClone(response);
                wrongResponse.signature.r = "0xce147ddddf12bb982973dc022ca648a642f89f3a2eb49bcf80640baa0307574e";

                const initialContractBalance = await ethers.provider.getBalance(await requestRegistry.getAddress());
                await expect(requestRegistry.connect(relayerSigner).processResponse(requestId, wrongResponse))
                    .to.be.revertedWith("Signature is not valid");
                const resultContractBalance = await ethers.provider.getBalance(await requestRegistry.getAddress());
                expect(resultContractBalance).to.eq(initialContractBalance);
            });

            it("feedId in response and feedId in request are different", async () => {
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
                    tdId: 1,
                };
                await time.setNextBlockTimestamp(response.dataItem.timestamp);

                const initialContractBalance = await ethers.provider.getBalance(await requestRegistry.getAddress());
                await expect(requestRegistry.connect(relayerSigner).processResponse(requestId, response))
                    .to.be.revertedWith("Response feed id is different from request feed id");
                const resultContractBalance = await ethers.provider.getBalance(await requestRegistry.getAddress());
                expect(resultContractBalance).to.eq(initialContractBalance);
            });

            it("tdId is not allowed to use", async () => {
                await prepareRequest({});

                const wrongResponse = structuredClone(response);
                wrongResponse.tdId = 2;

                const initialContractBalance = await ethers.provider.getBalance(await requestRegistry.getAddress());
                await expect(requestRegistry.connect(relayerSigner).processResponse(requestId, wrongResponse))
                    .to.be.revertedWith("Trust Domain is not allowed to use");
                const resultContractBalance = await ethers.provider.getBalance(await requestRegistry.getAddress());
                expect(resultContractBalance).to.eq(initialContractBalance);
            });

            const overTimeDifference = BigInt(30 * 60 + 1); // 30 min 1 sec
            const testCases: [string, bigint][] = [
                ["time skew is high. Response timestamp in the past", BigInt(response.dataItem.timestamp) + overTimeDifference],
                ["time skew is high. Response timestamp in the future", BigInt(response.dataItem.timestamp) - overTimeDifference],
            ];

            for (const [description, blockchainTime] of testCases) {
                it(description, async () => {
                    // note: move blockchain time to the past to be able to set `blockchainTime`
                    // otherwise we could get an error that last block time is higher than the one we want to set
                    await time.setNextBlockTimestamp(blockchainTime - overTimeDifference);

                    await prepareRequest({});
                    await time.setNextBlockTimestamp(blockchainTime);

                    const initialContractBalance = await ethers.provider.getBalance(await requestRegistry.getAddress());
                    await expect(requestRegistry.connect(relayerSigner).processResponse(requestId, response))
                        .to.be.revertedWith("Time skew is too high");
                    const resultContractBalance = await ethers.provider.getBalance(await requestRegistry.getAddress());
                    expect(resultContractBalance).to.eq(initialContractBalance);
                });
            }
        });
    });
});
