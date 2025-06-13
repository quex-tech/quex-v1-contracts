import env, {ignition} from "hardhat";
import {RequestActionTestContract__factory} from "../typechain";

import DeployRequestActionTestContractModule
    from "../ignition/modules/test_contracts/DeployRequestActionTestContractModule";
import {quexConfig, QuexNetworkConfig} from "./quex_config";

async function run() {
    const strategy = "basic";
    console.log(`Start deploy test contract with strategy ${strategy}`);

    const {requestActionTestContract} = await ignition.deploy(DeployRequestActionTestContractModule, {strategy: strategy});

    const testContract = RequestActionTestContract__factory.connect(
        await requestActionTestContract.getAddress(),
        requestActionTestContract.runner
    );

    console.log(`Test contract deployed at ${await testContract.getAddress()}`);

    const prevLastResponse = await testContract.getLastResponse();
    console.log(`prevLastResponse: ${prevLastResponse}`);

    await testContract.setUpFlow({value: ethers.parseEther("0.004")});
    console.log(`Flow configured`);

    const status = await testContract.getFlowSubscriptionStatus();
    console.log("Subscription status:", JSON.stringify(status, (_, v) => typeof v === 'bigint' ? v.toString() : v));

    try {
        const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));
        const tx = await testContract.createRequest({gasLimit: 500_000});
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

        for (let i = 0; i < 60; i++) {
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
    await testContract.withdraw();
    console.log("Subscription refunded");
}

run().catch(console.error);
