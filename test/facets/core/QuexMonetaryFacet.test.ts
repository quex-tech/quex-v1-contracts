import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { QuexMonetaryFacet, QuexMonetaryFacet__factory } from "../../../typechain";
import { ethers, ignition } from "hardhat";
import { expect } from "chai";
import { SnapshotRestorer, takeSnapshot } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import DeployQuexMonetaryFacetModule from "../../../ignition/modules/core/DeployQuexMonetaryFacetModule";

describe("QuexMonetaryFacet", () => {
    let owner: SignerWithAddress;
    let nonOwner: SignerWithAddress;
    let someAddress: SignerWithAddress;

    let testObject: QuexMonetaryFacet;

    let snapshot: SnapshotRestorer;

    before(async () => {
        [owner, nonOwner, someAddress] = await ethers.getSigners();
    });

    beforeEach(async () => {
        const { quexMonetaryFacet } = await ignition.deploy(DeployQuexMonetaryFacetModule, {defaultSender: await owner.getAddress()});
        testObject = QuexMonetaryFacet__factory.connect(await quexMonetaryFacet.getAddress(), quexMonetaryFacet.runner);
        snapshot = await takeSnapshot();
    });

    afterEach(async () => {
        await snapshot.restore();
    });

    describe("#setQuexFee", () => {
        it("sets quex fee", async () => {
            const quexFee = Math.round(Math.random() * 1000000);
            const flowId = Math.round(Math.random() * 1000000);

            await expect(testObject.connect(owner).setQuexFee(quexFee))
                .not.to.be.reverted;

            expect(await testObject.getQuexFee(flowId)).to.equal(quexFee);
        });

        describe("revert if", () => {
            it("sender is not owner", async () => {
                const quexFee = Math.round(Math.random() * 1000000);

                await expect(testObject.connect(nonOwner).setQuexFee(quexFee))
                    .to.be.revertedWithCustomError(testObject, "Ownable__NotOwner");
            });
        });
    });

    describe("#setTreasury", () => {
        it("sets treasury", async () => {
            const treasuryAddress = await someAddress.getAddress();

            await expect(testObject.connect(owner).setTreasury(treasuryAddress))
                .not.to.be.reverted;

            expect(await testObject.getTreasury()).to.equal(treasuryAddress);
        });

        describe("revert if", () => {
            it("sender is not owner", async () => {
                const treasuryAddress = await someAddress.getAddress();

                await expect(testObject.connect(nonOwner).setTreasury(treasuryAddress))
                    .to.be.revertedWithCustomError(testObject, "Ownable__NotOwner");
            });
        });
    });
});