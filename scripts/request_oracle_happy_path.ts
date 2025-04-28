import env, { ignition } from "hardhat";
import { RequestActionTestContract__factory } from "../typechain";

import DeployRequestActionTestContractModule from "../ignition/modules/test_contracts/DeployRequestActionTestContractModule";
import { quexConfig, QuexNetworkConfig } from "./quex_config";

async function run() {
    const quexNetworkConfig: QuexNetworkConfig = quexConfig[env.network.name];

    const { requestActionTestContract } = await ignition.deploy(DeployRequestActionTestContractModule, { strategy: quexNetworkConfig.disableCreate2 ? "basic" : "create2" });

    const testContract = RequestActionTestContract__factory.connect(
        await requestActionTestContract.getAddress(),
        requestActionTestContract.runner
    );

    const prevLastResponse = await testContract.getLastResponse();

    const requestValue = quexNetworkConfig.core.quexFee * 100n * (quexNetworkConfig.coinMultiplier ?? 1n);
    const tx = await testContract.createRequest({value: requestValue, gasLimit: 1_500_000});
    const txReceipt = await tx.wait();
    if (txReceipt?.status !== 1) {
        console.log("Creating request failed");
        console.log(txReceipt);
        return;
    }

    const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

    for (let i = 0; i < 60; i++) {
        const lastResponse = await testContract.getLastResponse();
        if (lastResponse[0] != prevLastResponse[0]) {
            console.log(`Attempt ${i + 1}: Test passed!`);
            return;
        }
        console.log(`Attempt ${i + 1}: data is not updated. Continue waiting`)
        await sleep(1000);
    }
}

run().catch(console.error);
