// Apply quex_config.supportedSvns to an already deployed QuexCore (owner-only), without a redeploy.
// Usage: ./with_keys.sh npx hardhat run scripts/allow_supported_svns.ts --network <network>
import {ethers} from "hardhat";
import {ITrustDomainRegistryExtended__factory} from "../typechain";
import {supportedSvns} from "./quex_config";
import {getQuexCoreAddress} from "./common";

async function main() {
    const [owner] = await ethers.getSigners();
    const registry = ITrustDomainRegistryExtended__factory.connect(await getQuexCoreAddress(), owner);
    for (const svn of supportedSvns.cpuSvnsToAdd) {
        if (await registry.isCpuSvnAllowed(svn)) {
            console.log(`cpu ${svn} already allowed`);
            continue;
        }
        await (await registry.allowCpuSvn(svn)).wait();
        console.log(`cpu ${svn} allowed`);
    }
    for (const svn of supportedSvns.teeTcbSvnsToAdd) {
        if (await registry.isTeeTcbSvnAllowed(svn)) {
            console.log(`tee ${svn} already allowed`);
            continue;
        }
        await (await registry.allowTeeTcbSvn(svn)).wait();
        console.log(`tee ${svn} allowed`);
    }
}

main().catch((e) => {
    console.error(e);
    process.exitCode = 1;
});
