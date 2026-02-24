import env, { ethers } from "hardhat";
import { IQuexActionFacet__factory } from "../typechain";
import { getQuexCoreAddress } from "./common";
import { quexConfig } from "./quex_config";

async function run() {
    const pastTimeSkew = BigInt(process.env.PAST_TIME_SKEW ?? "21600"); // 6 hours default
    const futureTimeSkew = BigInt(process.env.FUTURE_TIME_SKEW ?? "21600"); // 6 hours default

    const quexCoreAddress = await getQuexCoreAddress();
    console.log("QuexCore:", quexCoreAddress);

    const quexActions = IQuexActionFacet__factory.connect(quexCoreAddress, await ethers.provider.getSigner());

    const currentSkew = await quexActions.getTimeSkew();
    console.log(`Current time skew: past=${currentSkew[0]}, future=${currentSkew[1]}`);

    if (currentSkew[0] === pastTimeSkew && currentSkew[1] === futureTimeSkew) {
        console.log("Already set. Nothing to do.");
        return;
    }

    const networkConfig = quexConfig[env.network.name];
    const manager = await ethers.getSigner(<string>networkConfig.core.managerAddress);
    console.log(`Setting time skew: past=${pastTimeSkew}, future=${futureTimeSkew}`);
    const tx = await quexActions.connect(manager).setTimeSkew(pastTimeSkew, futureTimeSkew);
    console.log("Waiting for tx:", tx.hash);
    await tx.wait();

    const newSkew = await quexActions.getTimeSkew();
    console.log(`New time skew: past=${newSkew[0]}, future=${newSkew[1]}`);
    console.log("Done");
}

run().catch(console.error);
