// Read-only: simulate consumer.createRequest() and decode the revert reason.
import {ethers} from "hardhat";

async function main() {
    const consumer = process.env.BATCH_CONSUMER_ADDRESS ?? "0x289D66cE9ACd0E8D43156f83EF471ce1fA1529A7";
    const [deployer] = await ethers.getSigners();
    const c = await ethers.getContractAt("BatchRequestTestContract", consumer, deployer);
    console.log("flowId", await c.flowId(), "subId", await c.subscriptionId(), "owner", await c.owner());
    try {
        const r = await c.createRequest.staticCall();
        console.log("staticCall ok, would return requestId", r);
    } catch (e: any) {
        console.log("revert data:", e.data ?? e.info?.error?.data ?? "none");
        const iface = (await ethers.getContractAt("IQuexActionRegistry", consumer)).interface;
        if (e.data) {
            try {
                console.log("decoded:", iface.parseError(e.data));
            } catch {
                console.log("selector:", String(e.data).slice(0, 10));
            }
        }
        console.log("message:", e.shortMessage ?? e.message);
    }
}

main().catch((e) => {
    console.error(e);
    process.exitCode = 1;
});
