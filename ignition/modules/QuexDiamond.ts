import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const QuexDiamondModule = buildModule("QuexDiamond", (m) => {
    const quexDiamond = m.contract("QuexDiamond");
    m.call(quexDiamond, "init", []);
    return { quexDiamond };
});

export default QuexDiamondModule;