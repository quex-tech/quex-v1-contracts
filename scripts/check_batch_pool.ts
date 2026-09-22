// Read-only sanity check of the batch pool config after deploy.
import env from "hardhat";
import {ethers} from "hardhat";
import {quexConfig} from "./quex_config";
import {getQuexCoreAddress} from "./common";

async function main() {
    const chainId = env.network.config.chainId ?? 1;
    const deployments = await import(`../ignition/deployments/chain-${chainId}-batch/deployed_addresses.json`);
    const pool = deployments["DeployRequestOracleDiamondModule#QuexDiamond"];
    const cfg = quexConfig[env.network.name].request;
    const core = await getQuexCoreAddress();

    const monetary = await ethers.getContractAt("IConstantPriceMonetaryFacet", pool);
    const treasury = await ethers.getContractAt("ITreasuryFacet", pool);
    const quexAddr = await ethers.getContractAt("IQuexAddressFacet", pool);

    const fee = await monetary.getActionFee(0);
    const tr = await treasury.getTreasury();
    const qa = await quexAddr.getQuexAddress();
    console.log(`pool: ${pool}`);
    console.log(`actionFee: ${fee} (expected ${cfg.actionFee}) ${fee == cfg.actionFee ? "OK" : "MISMATCH"}`);
    console.log(`treasury: ${tr} (expected ${cfg.treasuryAddress}) ${tr == cfg.treasuryAddress ? "OK" : "MISMATCH"}`);
    console.log(`quexAddress: ${qa} (expected ${core}) ${qa == core ? "OK" : "MISMATCH"}`);
}

main().catch((e) => {
    console.error(e);
    process.exitCode = 1;
});
