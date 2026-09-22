// End-to-end smoke test for the batch pool: deploys (or reuses) the minimal
// BatchRequestTestContract, wires flow + subscription + deposit, fires
// createRequest and waits for the relayer callback.
//
// The batch action itself is off-chain (a .bin shipped to the relayer), so the
// flow references its content-addressed id directly.
//
// Usage:
//   BATCH_ACTION_ID=<uint256> [BATCH_CONSUMER_ADDRESS=0x...] \
//     npx hardhat run scripts/batch_happy_path.ts --network <network>
//
// Every step is guarded ("already done -> skip"), so reruns are safe; pass
// BATCH_CONSUMER_ADDRESS after the first run to reuse the deployed consumer.
import env, {ethers} from "hardhat";
import {IDepositManager__factory, BatchRequestTestContract, BatchRequestTestContract__factory} from "../typechain";
import {getQuexCoreAddress} from "./common";

const FLOW_GAS_LIMIT = 300_000n;

async function getBatchPoolAddress(): Promise<string> {
    const chainId = env.network.config.chainId ?? parseInt(await env.network.provider.send("eth_chainId", []));
    const deployments = await import(`../ignition/deployments/chain-${chainId}-batch/deployed_addresses.json`);
    return deployments["DeployRequestOracleDiamondModule#QuexDiamond"];
}

async function getConsumer(quexCore: string, pool: string): Promise<BatchRequestTestContract> {
    const [deployer] = await ethers.getSigners();
    const existing = process.env.BATCH_CONSUMER_ADDRESS;
    if (existing) {
        console.log(`Reusing consumer at ${existing}`);
        return BatchRequestTestContract__factory.connect(existing, deployer);
    }
    console.log("Deploying BatchRequestTestContract");
    const factory = await ethers.getContractFactory("BatchRequestTestContract", deployer);
    const consumer = (await factory.deploy(quexCore, pool)) as unknown as BatchRequestTestContract;
    await consumer.waitForDeployment();
    console.log(`Consumer deployed at ${await consumer.getAddress()} (export BATCH_CONSUMER_ADDRESS to reuse)`);
    return consumer;
}

async function main() {
    const actionIdRaw = process.env.BATCH_ACTION_ID;
    if (!actionIdRaw) throw new Error("Set BATCH_ACTION_ID to the uint256 action id of the shipped .bin");
    const actionId = BigInt(actionIdRaw);

    const quexCore = await getQuexCoreAddress();
    const pool = await getBatchPoolAddress();
    console.log(`QuexCore ${quexCore}, batch pool ${pool}, actionId ${actionId}`);

    const [deployer] = await ethers.getSigners();
    const consumer = await getConsumer(quexCore, pool);
    const depositManager = IDepositManager__factory.connect(quexCore, deployer);

    if (await consumer.flowId() == 0n) {
        console.log("Creating flow");
        const tx = await consumer.setUpFlow(actionId, FLOW_GAS_LIMIT);
        await tx.wait();
    }
    const flowId = await consumer.flowId();
    console.log(`Flow id: ${flowId}`);

    let subscriptionId = await consumer.subscriptionId();
    if (subscriptionId == 0n) {
        console.log("Creating subscription");
        const tx = await depositManager.createSubscription();
        const receipt = await tx.wait();
        const logs = await ethers.provider.getLogs({
            address: quexCore,
            topics: ["0x1d3015d7ba850fa198dc7b1a3f5d42779313a681035f77c8c03764c61005518d"], // SubscriptionCreated(uint256)
            fromBlock: receipt!.blockNumber,
            toBlock: receipt!.blockNumber,
        });
        subscriptionId = BigInt(logs.filter((log) => log.transactionHash === tx.hash)[0].topics[1]);
        console.log(`Subscription ${subscriptionId} created, binding to consumer`);
        await (await consumer.setSubscriptionId(subscriptionId)).wait();
    }
    console.log(`Subscription id: ${subscriptionId}`);

    if (!(await depositManager.hasAccessToSubscription(subscriptionId, await consumer.getAddress()))) {
        console.log("Adding consumer to subscription");
        await (await depositManager.addConsumer(subscriptionId, await consumer.getAddress())).wait();
    }

    const quexAction = await ethers.getContractAt("QuexActionFacet", quexCore);
    const [nativeFee, gasFee] = await quexAction.getRequestFee(flowId);
    const gasPrice = (await ethers.provider.getFeeData()).gasPrice!;
    const balance = await depositManager.withdrawableBalance(subscriptionId);
    const fund = nativeFee + gasFee * gasPrice * 3n - balance;
    console.log(`nativeFee ${nativeFee}, gasFee ${gasFee}, gasPrice ${gasPrice}, balance ${balance}`);
    if (fund > 0n) {
        console.log(`Funding subscription with ${fund} wei (${Number(fund) / 1e18} ETH)`);
        await (await depositManager.deposit(subscriptionId, {value: fund})).wait();
    }

    const prevTimestamp = await consumer.lastTimestamp();
    console.log("Creating request");
    // Explicit limit: estimateGas runs with gasprice=0, which zeroes the
    // maxRelayerRefund storage write and undershoots the real cost.
    const tx = await consumer.createRequest({gasLimit: 1_000_000});
    console.log(`createRequest tx ${tx.hash}, waiting`);
    await tx.wait();
    console.log(`Request id: ${await consumer.lastRequestId()}`);

    const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));
    for (let i = 0; i < 100; i++) {
        const ts = await consumer.lastTimestamp();
        if (ts != prevTimestamp) {
            const value = await consumer.lastValue();
            const error = await consumer.lastError();
            console.log(`Callback delivered: value=${value} (${Number(value) / 100} USD), error=${error}, timestamp=${ts}`);
            console.log(error == 0n ? "SMOKE TEST PASSED" : "callback arrived with non-zero error");
            return;
        }
        console.log(`attempt ${i + 1}: no callback yet, waiting`);
        await sleep(3000);
    }
    console.log("No callback after 5 minutes: check relayer worker logs");
    process.exitCode = 1;
}

main().catch((e) => {
    console.error(e);
    process.exitCode = 1;
});
