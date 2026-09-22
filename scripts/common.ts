import env from "hardhat";

async function getDeploymentAddress(deploymentName: string): Promise<string> {
    const chainId = env.network.config.chainId || parseInt(await env.network.provider.send("eth_chainId", []));
    const deployments = await import(`../ignition/deployments/chain-${chainId}/deployed_addresses.json`);
    const deploymentAddress = deployments[deploymentName];
    return deploymentAddress;
}

export async function getQuexCoreAddress(): Promise<string> {
    return getDeploymentAddress("QuexDiamond#QuexDiamond");
} 

// IGNITION_DEPLOYMENT_ID (e.g. chain-42161-batch) selects an extra pool deployment
// on the same chain; the core always comes from the chain's default deployment.
export async function getRequestOracleAddress(): Promise<string> {
    const deploymentId = process.env.IGNITION_DEPLOYMENT_ID;
    if (deploymentId) {
        const deployments = await import(`../ignition/deployments/${deploymentId}/deployed_addresses.json`);
        return deployments["DeployRequestOracleDiamondModule#QuexDiamond"];
    }
    return getDeploymentAddress("DeployRequestOracleDiamondModule#QuexDiamond");
}