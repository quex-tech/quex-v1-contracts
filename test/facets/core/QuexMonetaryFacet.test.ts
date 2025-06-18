import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { QuexDiamond__factory, QuexMonetaryFacet, QuexMonetaryFacet__factory } from "../../../typechain";
import { ethers, ignition } from "hardhat";
import { expect } from "chai";
import { SnapshotRestorer, takeSnapshot } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import AddQuexMonetaryFacetToQuexCoreModule from "../../../ignition/modules/core/AddQuexMonetaryFacetToQuexCoreModule";
import { ContractHelpers } from "../contract_helpers";
import QuexRoles = ContractHelpers.QuexRoles;

describe("QuexMonetaryFacet", () => {
    let owner: SignerWithAddress;
    let manager: SignerWithAddress;
    let nonOwner: SignerWithAddress;
    let someAddress: SignerWithAddress;

    let testObject: QuexMonetaryFacet;

    let snapshot: SnapshotRestorer;

    before(async () => {
        [owner, manager, nonOwner, someAddress] = await ethers.getSigners();
    });

    beforeEach(async () => {
        const { quexCoreDiamond } = await ignition.deploy(AddQuexMonetaryFacetToQuexCoreModule, {defaultSender: await owner.getAddress()});
        const diamond = QuexDiamond__factory.connect(await quexCoreDiamond.getAddress(), quexCoreDiamond.runner);
        await diamond.connect(owner).grantRole(QuexRoles.Manager, manager);
        testObject = QuexMonetaryFacet__factory.connect(await quexCoreDiamond.getAddress(), quexCoreDiamond.runner);
        snapshot = await takeSnapshot();
    });

    afterEach(async () => {
        await snapshot.restore();
    });

    describe("#setQuexFee", () => {
        it("sets quex fee", async () => {
            const quexFee = Math.round(Math.random() * 1000000);
            const flowId = Math.round(Math.random() * 1000000);

            await expect(testObject.connect(manager).setQuexFee(quexFee))
                .not.to.be.reverted;

            expect(await testObject.getQuexFee(flowId)).to.equal(quexFee);
        });

        describe("revert if", () => {
            it("sender is not manager", async () => {
                const quexFee = Math.round(Math.random() * 1000000);

                await expect(testObject.connect(nonOwner).setQuexFee(quexFee))
                    .to.be.revertedWith(RegExp("AccessControl:.*"));
            });

            it("sender is owner but not manager", async () => {
                const quexFee = Math.round(Math.random() * 1000000);

                await expect(testObject.connect(owner).setQuexFee(quexFee))
                    .to.be.revertedWith(RegExp("AccessControl:.*"));
            });
        });
    });

    describe("#setTreasury", () => {
        it("sets treasury", async () => {
            const treasuryAddress = await someAddress.getAddress();

            await expect(testObject.connect(manager).setTreasury(treasuryAddress))
                .not.to.be.reverted;

            expect(await testObject.getTreasury()).to.equal(treasuryAddress);
        });

        describe("revert if", () => {
            it("sender is not manager", async () => {
                const treasuryAddress = await someAddress.getAddress();

                await expect(testObject.connect(nonOwner).setTreasury(treasuryAddress))
                    .to.be.revertedWith(RegExp("AccessControl:.*"));
            });

            it("sender is owner but not manager", async () => {
                const treasuryAddress = await someAddress.getAddress();

                await expect(testObject.connect(owner).setTreasury(treasuryAddress))
                    .to.be.revertedWith(RegExp("AccessControl:.*"));
            });

            it("treasury address is zero address", async () => {
                const zeroAddress = ethers.ZeroAddress;

                await expect(testObject.connect(manager).setTreasury(zeroAddress))
                    .to.be.revertedWith("Treasury cannot be zero address");
            });
        });
    });
});