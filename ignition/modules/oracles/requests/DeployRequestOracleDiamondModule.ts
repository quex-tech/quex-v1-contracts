import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import QuexDiamond from "../../QuexDiamond";
import ProxyFactory from "../../ProxyFactory";

// keccak256("quex.requestOracle")
const salt = "0x750cd04ddfc45a86bbedd88ef564b39353ab2e9cd0b93c6faad15d56758e1f8b";

const DeployRequestOracleDiamondModule = buildModule("DeployRequestOracleDiamondModule", (m) => {
    const diamond = m.useModule(QuexDiamond).quexDiamond;
    const proxyFactory = m.useModule(ProxyFactory).proxyFactory;

    const callTx = m.call(proxyFactory, "deployMinimalProxy(address,bytes32)", [diamond, salt]);
    const proxyAddress = m.readEventArgument(callTx, "ProxyDeployed", 0);

    const requestsDiamond = m.contractAt("QuexDiamond", proxyAddress);
    m.call(requestsDiamond, "init", [m.getAccount(0)]);
    return { requestsDiamond };
});

export default DeployRequestOracleDiamondModule;