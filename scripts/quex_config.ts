import { AddressLike } from "ethers";

export interface QuexCoreNetworkConfig {
    quexFee: bigint;
    quexFulfillingGasCost: bigint;
    treasuryAddress: AddressLike;
    managerAddress: AddressLike;
}

export interface RequestOracleConfig {
    actionFee: bigint;
    treasuryAddress: AddressLike;
    managerAddress: AddressLike;
}

export interface QuexNetworkConfig {
    core: QuexCoreNetworkConfig;
    request: RequestOracleConfig;
}

export const quexConfig: { [key: string]: QuexNetworkConfig } = {
    localhost: {
        core: {
            quexFee: 1000n,
            quexFulfillingGasCost: 100n,
            treasuryAddress: "0xddBC5104B9515C074C33644C5D0C4994b0c31071",
            managerAddress: "0xddBC5104B9515C074C33644C5D0C4994b0c31071"
        },
        request: {
            actionFee: 250n,
            treasuryAddress: "0xddBC5104B9515C074C33644C5D0C4994b0c31071",
            managerAddress: "0xddBC5104B9515C074C33644C5D0C4994b0c31071"
        }
    },
    arbitrum: {
        core: {
            quexFee: 30_000_000_000_000n,
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: "0x6F373Fd4c0F501F5F6828bA21B1EA88fE4596cF6",
            managerAddress: "0xfC030Fe3499C1b34F4cdFF61078e44869661Dd24"
        },
        request: {
            actionFee: 0n,
            treasuryAddress: "0x6F373Fd4c0F501F5F6828bA21B1EA88fE4596cF6",
            managerAddress: "0xfC030Fe3499C1b34F4cdFF61078e44869661Dd24"
        }
    },
    arbitrumSepolia: {
        core: {
            quexFee: 30_000_000_000_000n,
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: "0x6F373Fd4c0F501F5F6828bA21B1EA88fE4596cF6",
            managerAddress: "0xfC030Fe3499C1b34F4cdFF61078e44869661Dd24"
        },
        request: {
            actionFee: 0n,
            treasuryAddress: "0x6F373Fd4c0F501F5F6828bA21B1EA88fE4596cF6",
            managerAddress: "0xfC030Fe3499C1b34F4cdFF61078e44869661Dd24"
        }
    },
    arbitrumOne: {
        core: {
            quexFee: 30_000_000_000_000n,
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: "0x6F373Fd4c0F501F5F6828bA21B1EA88fE4596cF6",
            managerAddress: "0xfC030Fe3499C1b34F4cdFF61078e44869661Dd24"
        },
        request: {
            actionFee: 0n,
            treasuryAddress: "0x6F373Fd4c0F501F5F6828bA21B1EA88fE4596cF6",
            managerAddress: "0xfC030Fe3499C1b34F4cdFF61078e44869661Dd24"
        }
    }
}