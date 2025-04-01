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
    disableCreate2?: boolean;
    coinMultiplier?: bigint;
    core: QuexCoreNetworkConfig;
    request: RequestOracleConfig;
}

export const quexConfig: { [key: string]: QuexNetworkConfig } = {
    localhost: {
        core: {
            quexFee: 30_000_000_000_000n,
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
            managerAddress: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
        },
        request: {
            actionFee: 0n,
            treasuryAddress: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
            managerAddress: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
        }
    },
    arbitrumSepolia: {
        core: {
            quexFee: 30_000_000_000_000n, // 0.00003 ETH
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
            quexFee: 30_000_000_000_000n, // 0.00003 ETH
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
    bscMainnet: {
        core: {
            quexFee: 100_000_000_000_000n, // 0.0001 BNB
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
    bscTestnet: {
        core: {
            quexFee: 100_000_000_000_000n, // 0.0001 BNB
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
    xdcMainnet: {
        core: {
            quexFee: 800_000_000_000_000_000n, // 0.8 XDC
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
    xdcApothem: {
        core: {
            quexFee: 800_000_000_000_000_000n, // 0.8 XDC
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
    berachain: {
        core: {
            quexFee: 9_000_000_000_000_000n, // 0.009 BERA
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
    berachainBepolia: {
        disableCreate2: true,
        core: {
            quexFee: 9_000_000_000_000_000n, // 0.009 BERA
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
    ethereumSepolia: {
        core: {
            quexFee: 30_000_000_000_000n, // 0.00003 ETH
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
    ethereum: {
        core: {
            quexFee: 30_000_000_000_000n, // 0.00003 ETH
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
    avalancheFuji: {
        core: {
            quexFee: 3_000_000_000_000_000n, // 0.003 AVAX
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
    avalanche: {
        core: {
            quexFee: 3_000_000_000_000_000n, // 0.003 AVAX
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
    celoMainnet: {
        disableCreate2: true,
        core: {
            quexFee: 200_000_000_000_000_000n, // 0.2 CELO
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
    celoAlfajores: {
        core: {
            quexFee: 200_000_000_000_000_000n, // 0.2 CELO
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
    redbellyTestnet: { // DO NOT USE AS A TEMPLATE. UNUSUAL SETTINGS
        disableCreate2: true,
        core: {
            quexFee: 2_000_000_000_000_000_000n, // 2 RBNT
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: "0xddBC5104B9515C074C33644C5D0C4994b0c31071",
            managerAddress: "0xddBC5104B9515C074C33644C5D0C4994b0c31071"
        },
        request: {
            actionFee: 0n,
            treasuryAddress: "0xddBC5104B9515C074C33644C5D0C4994b0c31071",
            managerAddress: "0xddBC5104B9515C074C33644C5D0C4994b0c31071"
        }
    },
    redbellyMainnet: { // DO NOT USE AS A TEMPLATE. UNUSUAL SETTINGS
        disableCreate2: true,
        core: {
            quexFee: 2_000_000_000_000_000_000n, // 2 RBNT
            quexFulfillingGasCost: 110_000n,
            treasuryAddress: "0x450Ab8FAA76C561606400eF6a30397c396D524Ba",
            managerAddress: "0x450Ab8FAA76C561606400eF6a30397c396D524Ba"
        },
        request: {
            actionFee: 0n,
            treasuryAddress: "0x450Ab8FAA76C561606400eF6a30397c396D524Ba",
            managerAddress: "0x450Ab8FAA76C561606400eF6a30397c396D524Ba"
        }
    },
    hederaTestnet: {
        coinMultiplier: 10_000_000_000n,
        disableCreate2: true,
        core: {
            quexFee: 30_000_000n, // 0.3 HBAR
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
    hederaMainnet: {
        coinMultiplier: 10_000_000_000n,
        disableCreate2: true,
        core: {
            quexFee: 30_000_000n, // 0.3 HBAR
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
}