import { AddressLike } from "ethers";

const DEFAULT_TREASURY = process.env.QUEX_TREASURY_ADDRESS ?? "0x6F373Fd4c0F501F5F6828bA21B1EA88fE4596cF6";
const DEFAULT_MANAGER = process.env.QUEX_MANAGER_ADDRESS ?? "0xfC030Fe3499C1b34F4cdFF61078e44869661Dd24";
const LOCALHOST_ADDR = process.env.LOCALHOST_DEPLOYER ?? "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
const REDBELLY_TESTNET_ADDR = process.env.REDBELLY_TESTNET_DEPLOYER ?? "0xddBC5104B9515C074C33644C5D0C4994b0c31071";
const REDBELLY_MAINNET_ADDR = process.env.REDBELLY_MAINNET_DEPLOYER ?? "0x450Ab8FAA76C561606400eF6a30397c396D524Ba";

export interface SupportedSvns {
    cpuSvnsToAdd: string[];
    cpuSvnsToRemove: string[];
    teeTcbSvnsToAdd: string[];
    teeTcbSvnsToRemove: string[];
}

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
    maxResponseBlocks: bigint;
}

export interface QuexNetworkConfig {
    disableCreate2?: boolean;
    coinMultiplier?: bigint;
    core: QuexCoreNetworkConfig;
    request: RequestOracleConfig;
}

export const supportedSvns: SupportedSvns = {
    cpuSvnsToAdd: ["0x0202191b03ff00060000000000000000"],
    cpuSvnsToRemove: [],
    teeTcbSvnsToAdd: ["0x05010200000000000000000000000000"],
    teeTcbSvnsToRemove: []
}

export const quexConfig: { [key: string]: QuexNetworkConfig } = {
    localhost: {
        core: {
            quexFee: 30_000_000_000_000n,
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: LOCALHOST_ADDR,
            managerAddress: LOCALHOST_ADDR
        },
        request: {
            actionFee: 0n,
            treasuryAddress: LOCALHOST_ADDR,
            managerAddress: LOCALHOST_ADDR,
            maxResponseBlocks: 100n
        }
    },
    arbitrumSepolia: {
        core: {
            quexFee: 30_000_000_000_000n, // 0.00003 ETH
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER
        },
        request: {
            actionFee: 0n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER,
            maxResponseBlocks: 1200n
        }
    },
    arbitrumOne: {
        core: {
            quexFee: 30_000_000_000_000n, // 0.00003 ETH
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER
        },
        request: {
            actionFee: 0n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER,
            maxResponseBlocks: 1200n
        }
    },
    bscMainnet: {
        core: {
            quexFee: 100_000_000_000_000n, // 0.0001 BNB
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER
        },
        request: {
            actionFee: 0n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER,
            maxResponseBlocks: 200n
        }
    },
    bscTestnet: {
        core: {
            quexFee: 100_000_000_000_000n, // 0.0001 BNB
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER
        },
        request: {
            actionFee: 0n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER,
            maxResponseBlocks: 200n
        }
    },
    xdcMainnet: {
        core: {
            quexFee: 800_000_000_000_000_000n, // 0.8 XDC
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER
        },
        request: {
            actionFee: 0n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER,
            maxResponseBlocks: 150n
        }
    },
    xdcApothem: {
        core: {
            quexFee: 800_000_000_000_000_000n, // 0.8 XDC
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER
        },
        request: {
            actionFee: 0n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER,
            maxResponseBlocks: 150n
        }
    },
    berachain: {
        core: {
            quexFee: 9_000_000_000_000_000n, // 0.009 BERA
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER
        },
        request: {
            actionFee: 0n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER,
            maxResponseBlocks: 150n
        }
    },
    berachainBepolia: {
        disableCreate2: true,
        core: {
            quexFee: 9_000_000_000_000_000n, // 0.009 BERA
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER
        },
        request: {
            actionFee: 0n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER,
            maxResponseBlocks: 150n
        }
    },
    ethereumSepolia: {
        core: {
            quexFee: 30_000_000_000_000n, // 0.00003 ETH
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER
        },
        request: {
            actionFee: 0n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER,
            maxResponseBlocks: 25n
        }
    },
    ethereum: {
        core: {
            quexFee: 30_000_000_000_000n, // 0.00003 ETH
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER
        },
        request: {
            actionFee: 0n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER,
            maxResponseBlocks: 25n
        }
    },
    avalancheFuji: {
        core: {
            quexFee: 3_000_000_000_000_000n, // 0.003 AVAX
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER
        },
        request: {
            actionFee: 0n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER,
            maxResponseBlocks: 200n
        }
    },
    avalanche: {
        core: {
            quexFee: 3_000_000_000_000_000n, // 0.003 AVAX
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER
        },
        request: {
            actionFee: 0n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER,
            maxResponseBlocks: 200n
        }
    },
    celoMainnet: {
        disableCreate2: true,
        core: {
            quexFee: 200_000_000_000_000_000n, // 0.2 CELO
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER
        },
        request: {
            actionFee: 0n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER,
            maxResponseBlocks: 300n
        }
    },
    celoAlfajores: {
        core: {
            quexFee: 200_000_000_000_000_000n, // 0.2 CELO
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER
        },
        request: {
            actionFee: 0n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER,
            maxResponseBlocks: 300n
        }
    },
    redbellyTestnet: { // DO NOT USE AS A TEMPLATE. UNUSUAL SETTINGS
        disableCreate2: true,
        core: {
            quexFee: 2_000_000_000_000_000_000n, // 2 RBNT
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: REDBELLY_TESTNET_ADDR,
            managerAddress: REDBELLY_TESTNET_ADDR
        },
        request: {
            actionFee: 0n,
            treasuryAddress: REDBELLY_TESTNET_ADDR,
            managerAddress: REDBELLY_TESTNET_ADDR,
            maxResponseBlocks: 100n
        }
    },
    redbellyMainnet: { // DO NOT USE AS A TEMPLATE. UNUSUAL SETTINGS
        disableCreate2: true,
        core: {
            quexFee: 2_000_000_000_000_000_000n, // 2 RBNT
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: REDBELLY_MAINNET_ADDR,
            managerAddress: REDBELLY_MAINNET_ADDR
        },
        request: {
            actionFee: 0n,
            treasuryAddress: REDBELLY_MAINNET_ADDR,
            managerAddress: REDBELLY_MAINNET_ADDR,
            maxResponseBlocks: 100n
        }
    },
    hederaTestnet: {
        coinMultiplier: 10_000_000_000n,
        disableCreate2: true,
        core: {
            quexFee: 30_000_000n, // 0.3 HBAR
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER
        },
        request: {
            actionFee: 0n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER,
            maxResponseBlocks: 150n
        }
    },
    hederaMainnet: {
        coinMultiplier: 10_000_000_000n,
        disableCreate2: true,
        core: {
            quexFee: 30_000_000n, // 0.3 HBAR
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER
        },
        request: {
            actionFee: 0n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER,
            maxResponseBlocks: 150n
        }
    },
    waterfallTestnet9: {
        disableCreate2: true,
        core: {
            quexFee: 4000_000_000_000_000_000_000n, // 4000 WATER
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER
        },
        request: {
            actionFee: 0n,
            treasuryAddress: DEFAULT_TREASURY,
            managerAddress: DEFAULT_MANAGER,
            maxResponseBlocks: 200n
        }
    }
}