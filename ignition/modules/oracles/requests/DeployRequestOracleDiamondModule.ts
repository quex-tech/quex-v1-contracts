import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import QuexDiamond from "../../QuexDiamond";

const DeployRequestOracleDiamondModule = buildModule("DeployRequestOracleDiamondModule", (m) => {
    // todo: minimal proxy
    const diamond = m.useModule(QuexDiamond).quexDiamond;
    return { requestsDiamond: diamond };
});

export default DeployRequestOracleDiamondModule;