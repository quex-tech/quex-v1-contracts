import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import {
    FlowFacet,
    FlowFacet__factory,
} from "../../../typechain";
import { ethers, ignition } from "hardhat";
import { expect } from "chai";
import { SnapshotRestorer, takeSnapshot } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import FlowFacetModule from "../../../ignition/modules/core/FlowFacet";
import { FlowStruct } from "../../../typechain/contracts/facets/flow/FlowFacet";

describe("FlowFacet", () => {
    let owner: SignerWithAddress;
    let nonOwner: SignerWithAddress;
    let pool: SignerWithAddress;
    let consumer: SignerWithAddress;

    let testObject: FlowFacet;

    let snapshot: SnapshotRestorer;

    before(async () => {
        [owner, nonOwner, pool, consumer] = await ethers.getSigners();
    });

    beforeEach(async () => {
        const { flowFacet } = await ignition.deploy(FlowFacetModule, {defaultSender: await owner.getAddress()});
        testObject = FlowFacet__factory.connect(await flowFacet.getAddress(), flowFacet.runner);
        snapshot = await takeSnapshot();
    });

    afterEach(async () => {
        await snapshot.restore();
    });

    describe("#createFlow", () => {
        it("creates flow", async () => {
            const flow: FlowStruct = {
                actionId: 1,
                callback: "0x00112233",
                consumer: await consumer.getAddress(),
                gasLimit: 1,
                pool: await pool.getAddress(),
            }

            await expect(testObject.createFlow(flow))
                .not.to.be.reverted;

            const flowResult = await testObject.getFlow(1);
            expect(flowResult.actionId).to.equal(flow.actionId);
            expect(flowResult.callback).to.equal(flow.callback);
            expect(flowResult.consumer).to.equal(flow.consumer);
            expect(flowResult.gasLimit).to.equal(flow.gasLimit);
            expect(flowResult.pool).to.equal(flow.pool);
        });
    });
});