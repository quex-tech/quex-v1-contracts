import env, { ethers, ignition } from "hardhat";
import { QuexNetworkConfig, quexConfig } from "./quex_config";
import RequestOracleCompleteDeployAndConfigurationModule from "../ignition/modules/oracles/requests/RequestOracleDeployAndConfigurationModule";
import { ITrustDomainPolicyFacet__factory } from "../typechain";

const run = async (quexNetworkConfig: QuexNetworkConfig, tdId: bigint) => {
    console.log(`Adding TD ${tdId} to request oracle`);
    const { requestsDiamond } = await ignition.deploy(RequestOracleCompleteDeployAndConfigurationModule, { strategy: quexNetworkConfig.disableCreate2 ? "basic" : "create2" });
    const tdFacet = ITrustDomainPolicyFacet__factory.connect(await requestsDiamond.getAddress(), requestsDiamond.runner);
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