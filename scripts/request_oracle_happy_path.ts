import { ignition } from "hardhat";
import { RequestActionTestContract__factory } from "../typechain";

import DeployRequestActionTestContractModule from "../ignition/modules/test_contracts/DeployRequestActionTestContractModule";

async function run() {
    const { requestActionTestContract } = await ignition.deploy(DeployRequestActionTestContractModule);

    const testContract = RequestActionTestContract__factory.connect(
        await requestActionTestContract.getAddress(),
        requestActionTestContract.runner
    );

    const prevLastResponse = await testContract.getLastResponse();

    await testContract.createRequest({value: 10_000_000_000_000_000n, gasLimit: 1_500_000});

    const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

    for (let i = 0; i < 30; i++) {
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
