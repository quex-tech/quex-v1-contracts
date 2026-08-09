import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import QuexDiamond from "../../QuexDiamond";
import ProxyFactory from "../../ProxyFactory";

// keccak256("quex.batchRequestOracle")
const salt = "0x07d8be17d200369051099b1d35436f8736e32ce97fd8ee77fcd06ee80ca0f380";

const DeployBatchRequestOracleDiamondModule = buildModule("DeployBatchRequestOracleDiamondModule", (m) => {
    const diamond = m.useModule(QuexDiamond).quexDiamond;
    const proxyFactory = m.useModule(ProxyFactory).proxyFactory;

    const callTx = m.call(proxyFactory, "deployMinimalProxy(address,bytes32)", [diamond, salt]);
    const proxyAddress = m.readEventArgument(callTx, "ProxyDeployed", 0);

    const batchRequestsDiamond = m.contractAt("QuexDiamond", proxyAddress);
    m.call(batchRequestsDiamond, "init", [m.getAccount(0)]);
    return { batchRequestsDiamond };
});

export default DeployBatchRequestOracleDiamondModule;
