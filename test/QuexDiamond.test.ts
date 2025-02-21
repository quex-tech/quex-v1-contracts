import { HardhatEthersSigner, SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { describeBehaviorOfSolidStateDiamond, describeBehaviorOfAccessControl } from "@solidstate/spec";
import { expect } from "chai";
import { ethers } from "hardhat";
import {
    QuexDiamond,
    QuexDiamond__factory
} from "../typechain";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";

describe("QuexDiamond", () => {
    let owner: SignerWithAddress;
    let nomineeOwner: SignerWithAddress;
    let nonOwner: SignerWithAddress;

    let instance: QuexDiamond;

    let facetCuts: any[] = [];
    let immutableSelectors: string[] = [];

    before(async () => {
        [owner, nomineeOwner, nonOwner] = await ethers.getSigners();
    });

    beforeEach(async () => {
        const [deployer] = await ethers.getSigners();
        instance = await new QuexDiamond__factory(deployer).deploy();
    });

    describe("#init", () => {
        it("transfers ownership to caller", async () => {
            const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");

            await expect(instance.connect(owner).init())
                .to.emit(instance, "OwnershipTransferred")
                .withArgs(anyValue, owner)
        });

        it("grants default admin role to caller", async () => {
            await expect(instance.connect(owner).init())
                .to.emit(instance, "RoleGranted")
                .withArgs(ethers.ZeroHash, owner, owner);
        });

        it("performs facet cut", async () => {
            await expect(instance.init())
                .to.emit(instance, "DiamondCut");
        });

        describe("reverts if", () => {
            it("already called", async() => {
                await instance.init();

                await expect(instance.init())
                    .to.be.revertedWithCustomError(instance, "Initializable__AlreadyInitialized");
            })
        })
    });

    describe("::initialized diamond", () => {
        beforeEach(async () => {
            await instance.init();

            const facets = await instance.facets.staticCall();

            expect(facets).to.have.lengthOf(1);

            facetCuts[0] = {
                target: await instance.getAddress(),
                action: 0,
                selectors: facets[0].selectors
            };

            for (const selector of facetCuts[0].selectors) {
                immutableSelectors.push(selector);
            }

            expect(immutableSelectors.length).to.be.gt(0);
        });

        describeBehaviorOfSolidStateDiamond(
            async () => instance,
            {
                getOwner: async () => owner,
                getNomineeOwner: async () => nomineeOwner,
                getNonOwner: async () => nonOwner,
                facetFunction: "",
                facetFunctionArgs: [],
                facetCuts,
                fallbackAddress: ethers.ZeroAddress,
                immutableSelectors
            },
            ["fallback()", "::ERC165Base"]
        );

        describeBehaviorOfAccessControl(
            {
                getAdmin: async () => owner,
                getNonAdmin: async () => nonOwner,
                deploy: async () => instance
            }
        );
    });

});
