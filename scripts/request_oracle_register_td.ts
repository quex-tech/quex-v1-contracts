import env, { ethers } from "hardhat";
import { QuexNetworkConfig, quexConfig } from "./quex_config";
import { getRequestOracleAddress } from "./common";

const run = async (quexNetworkConfig: QuexNetworkConfig, tdId: bigint) => {
    console.log(`Adding TD ${tdId} to request oracle`);
    const requestOracleAddress = await getRequestOracleAddress();
    const tdFacet = await ethers.getContractAt("ITrustDomainPolicyFacet", requestOracleAddress);
    const tx = await tdFacet
        .connect(await ethers.getSigner(<string>quexNetworkConfig.request.managerAddress))
        .addToPool(tdId);
    await tx.wait();
    console.log(`TD ${tdId} added to request oracle\nDone!`);
}

if (require.main === module) {
    let input = '';
    process.stdin.on('data', chunk => {
        input += chunk;
    });
    process.stdin.on('end', () => {
        const tdId = BigInt(input);
        run(quexConfig[env.network.name], tdId).catch(console.error);
    });
}

export { run };