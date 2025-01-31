import { AddressLike } from "ethers";

export interface QuexCoreNetworkConfig {
    quexFee: bigint;
    quexFulfillingGasCost: bigint;
    treasuryAddress: AddressLike;
}

export interface RequestOracleConfig {
    actionFee: bigint;
    treasuryAddress: AddressLike;
}

export interface QuexNetworkConfig {
    core: QuexCoreNetworkConfig;
    request: RequestOracleConfig;
}

export const quexConfig: { [key: string]: QuexNetworkConfig } = {
    arbitrumSepolia: {
        core: {
            quexFee: 1000n,
            quexFulfillingGasCost: 100n,
            treasuryAddress: "0xddBC5104B9515C074C33644C5D0C4994b0c31071"
        },
        request: {
            actionFee: 250n,
            treasuryAddress: "0xddBC5104B9515C074C33644C5D0C4994b0c31071"
        }
    }
}