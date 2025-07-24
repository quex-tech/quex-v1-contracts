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

export async function getRequestOracleAddress(): Promise<string> {
    return getDeploymentAddress("DeployRequestOracleDiamondModule#QuexDiamond");
}