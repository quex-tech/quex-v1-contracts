import {expect} from "chai";
import "@nomicfoundation/hardhat-ethers";
import {time, reset} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import {V1FeedRegistry, V1TrustDomainRegistry} from "../typechain";
import {ContractHelpers} from "./contract_helpers";
import {RequestResultStruct} from "../typechain/interfaces/IV1RequestRegistry";

describe("RequestRegistry", function () {
    let trustDomainRegistry: V1TrustDomainRegistry;
    let feedRegistry: V1FeedRegistry;

    before(async () => {
        await reset();
        await time.setNextBlockTimestamp(1731070829);
        trustDomainRegistry = await ContractHelpers.TrustDomainRegistry.create_configured();
        feedRegistry = await ContractHelpers.FeedRegistry.create_configured(trustDomainRegistry);
    });

    it("Full on-chain flow", async function () {
        const feedId = await ContractHelpers.FeedRegistry.create_feed(feedRegistry);
        const requestRegistry = await ContractHelpers.RequestRegistry.create_configured(feedRegistry, trustDomainRegistry);

        const callbackContract = await ContractHelpers.TestQuexResponseProcessor.deploy();
        const callbackMethod = callbackContract.interface.getFunction("goodProcessor").selector;

        const requestId = await ContractHelpers.RequestRegistry.sendRequest(requestRegistry, feedId, await callbackContract.getAddress(), callbackMethod, 10000, BigInt("1000000000000000000"));

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
            tdId: 1
        }

        const res = await requestRegistry.processResponse(requestId, response);
        await requestRegistry.requests("")
        console.log(res);
    });
});

