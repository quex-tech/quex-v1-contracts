import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ProxyFactoryModule = buildModule("ProxyFactory", (m) => {
    const proxyFactory = m.contract("ProxyFactory");
    return { proxyFactory };
});

export default ProxyFactoryModule;