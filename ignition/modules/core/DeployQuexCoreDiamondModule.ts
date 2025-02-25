import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import QuexDiamond from "../QuexDiamond";

const DeployQuexCoreDiamondModule = buildModule("DeployQuexCoreDiamondModule", (m) => {
    // use base QuexDiamond as QuexCore's diamond without proxy
    const diamond = m.useModule(QuexDiamond).quexDiamond;
    return { quexCoreDiamond: diamond };
});

export default DeployQuexCoreDiamondModule;