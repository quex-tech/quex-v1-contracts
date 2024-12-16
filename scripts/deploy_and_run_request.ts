import { ignition } from "hardhat";
import FeedFacetTestConfiguration from "../ignition/modules/FeedFacetTestConfiguration";
import { OnChainFeedRequestTestContract__factory } from "../typechain";
import { ethers } from "ethers";

async function run() {
    const {
        callbackContract
    } = await ignition.deploy(FeedFacetTestConfiguration);

    const userContract = OnChainFeedRequestTestContract__factory.connect(await callbackContract.getAddress(), callbackContract.runner);
    const tx = await userContract.request(600000, {value: ethers.WeiPerEther / 1000n });
    const txReceipt = await tx.wait();
    console.log(tx);
    console.log(txReceipt);
}

run().catch(console.error);