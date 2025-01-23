import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const QuexDiamondModule = buildModule("QuexDiamond", (m) => {
    const quexDiamond = m.contract("QuexDiamond");

    return { quexDiamond };
});

export default QuexDiamondModule;