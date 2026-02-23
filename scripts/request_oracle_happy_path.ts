import env, {ethers, ignition} from "hardhat";
import {IDepositManager, IDepositManager__factory, RequestActionTestContract__factory} from "../typechain";

import DeployRequestActionTestContractModule
    from "../ignition/modules/test_contracts/DeployRequestActionTestContractModule";
import {quexConfig, QuexNetworkConfig} from "./quex_config";
import DeployQuexCoreDiamondModule from "../ignition/modules/core/DeployQuexCoreDiamondModule";

async function run(quexNetworkConfig: QuexNetworkConfig) {
    const strategy = quexNetworkConfig.disableCreate2 ? "basic" : "create2";
    console.log(`Start deploy test contract with strategy ${strategy}`);

    const {requestActionTestContract} = await ignition.deploy(DeployRequestActionTestContractModule, {strategy: strategy});
    const {quexCoreDiamond} = await ignition.deploy(DeployQuexCoreDiamondModule, {strategy: strategy});

    const testContract = RequestActionTestContract__factory.connect(
        await requestActionTestContract.getAddress(),
        requestActionTestContract.runner
    );

    const depositManager = IDepositManager__factory.connect(
        await quexCoreDiamond.getAddress(),
        quexCoreDiamond.runner
    );

    console.log(`Test contract deployed at ${await testContract.getAddress()}`);

    let status = await testContract.getFlowSubscriptionStatus();
    printFlowSubscriptionStatus(status);

    let subscriptionId = status[1];

    if (status[0] == 0n) { // flow id is 0, so we need to create it
        console.log("Creating flow");
        await testContract.setUpFlow();
        console.log(`Flow configured`);
    }

    if (subscriptionId == 0n) { // subscription id is 0, so we need to create it
        console.log("Creating subscription");
        subscriptionId = await createSubscription(depositManager, await quexCoreDiamond.getAddress());
        if (subscriptionId == 0n) {
            console.log("Creating subscription failed");
            return;
        }
        console.log(`Subscription ${subscriptionId} created. Setting it to test contract`);
        const tx = await testContract.setSubscriptionId(subscriptionId);
        const txReceipt = await tx.wait();
        if (txReceipt?.status !== 1) {
            console.log("Setting subscription id failed");
            return;
        }
        console.log(`Subscription id set`);
    }

    if (status[3] == false) { // subscription is not valid, so we need to add consumer
        console.log("Adding consumer to subscription");
        const tx = await depositManager.addConsumer(subscriptionId, await testContract.getAddress());
        const txReceipt = await tx.wait();
        if (txReceipt?.status !== 1) {
            console.log("Adding consumer failed");
            return;
        }
        console.log(`Consumer added`);
    }

    const gasPrice = (await ethers.provider.getFeeData()).gasPrice;
    console.log(`Gas price: ${gasPrice} wei (${Number(gasPrice!) / 10 ** 9} gwei)`);
    console.log(`Native fee: ${status[4]} wei (${Number(status[4]) / 10 ** 18} ETH)`);
    console.log(`Gas fee: ${status[5]}`);
    const fund = status[4] + status[5] * gasPrice! * 3n - status[2]; // native fee + gas fee * 3 -  current subscription balance
    if (fund > 0n) { // fund is positive, so we need to deposit
        console.log(`Funding subscription ${subscriptionId} with ${fund} wei`);
        const tx = await depositManager.deposit(subscriptionId, {value: fund});
        const txReceipt = await tx.wait();
        if (txReceipt?.status !== 1) {
            console.log("Depositing failed");
            return;
        }
        console.log(`Subscription funded`);
    }

    status = await testContract.getFlowSubscriptionStatus();
    console.log("Subscription status after configuration:");
    printFlowSubscriptionStatus(status);

    const prevLastResponse = await testContract.getLastResponse();
    console.log(`prevLastResponse: ${prevLastResponse}`);

    const lastRequestId = await testContract.getLastRequestId();
    console.log(`lastRequestId: ${lastRequestId}`);

    try {
        const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));
        console.log("Creating request");
        const tx = await testContract.createRequest({gasLimit: 1_000_000, type: 0});
        console.log(`Creating request tx ${tx.hash}. Waiting for tx receipt`);
        const txReceipt = await tx.wait();
        if (txReceipt?.status !== 1) {
            console.log("Creating request failed");
            console.log(txReceipt);
            return;
        }
        console.log(`Request created: ${tx.hash}`);
        await sleep(1000);

        const request = await testContract.getLastRequest()
        console.log("Last request:", JSON.stringify(request, (_, v) => typeof v === 'bigint' ? v.toString() : v));

        for (let i = 0; i < 100; i++) {
            const lastResponse = await testContract.getLastResponse();
            if (lastResponse[0] != prevLastResponse[0]) {
                console.log(`Attempt ${i + 1}: Test passed!`);
                return;
            }
            console.log(`Attempt ${i + 1}: data is not updated. Continue waiting`)
            await sleep(1000);
        }
    } catch (e) {
        console.error("failed:");
        console.error(e);
    }
    await depositManager.withdraw(subscriptionId, (await ethers.getSigners())[0].address);
    console.log("Subscription refunded");
}

function printFlowSubscriptionStatus(status: [bigint, bigint, bigint, boolean, bigint, bigint]) {
    console.log(`Flow ID: ${status[0]}`);
    console.log(`Subscription ID: ${status[1]}`);
    console.log(`Subscription withdrawable balance: ${status[2]}`);
    console.log(`Is subscription valid: ${status[3]}`);
    console.log(`Native fee: ${status[4]}`);
    console.log(`Gas fee: ${status[5]}`);
}

async function createSubscription(depositManager: IDepositManager, quexCoreAddress: string): Promise<bigint> {
    const tx = await depositManager.createSubscription();
    const txReceipt = await tx.wait();
    if (txReceipt?.status !== 1) {
        console.log("Creating subscription failed");
        console.log(txReceipt);
        return 0n;
    }

    const logs = await ethers.provider.getLogs({
        address: quexCoreAddress,
        topics: [
            "0x1d3015d7ba850fa198dc7b1a3f5d42779313a681035f77c8c03764c61005518d" // SubscriptionCreated(uint256)
        ],
        fromBlock: txReceipt.blockNumber,
        toBlock: txReceipt.blockNumber
    });
    const subscriptionId = BigInt(logs.filter((log: any) => log.transactionHash === tx.hash)[0].topics[1]);
    return subscriptionId;
}

if (require.main === module) {
    run(quexConfig[env.network.name]).catch(console.error);
}

export { run };