import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";
import "hardhat-gas-reporter";

const quexDeployerPrivateKey = process.env.QUEX_DEPLOYER_PRIVATE_KEY ?? "0x0000000000000000000000000000000000000000000000000000000000000001";
const quexManagerPrivateKey = process.env.QUEX_MANAGER_PRIVATE_KEY ?? "0x0000000000000000000000000000000000000000000000000000000000000001";

const quexRedbellyTestnetPrivateKey = process.env.QUEX_REDBELLY_TESTNET_PRIVATE_KEY ?? "0x0000000000000000000000000000000000000000000000000000000000000001";
const quexRedbellyMainnetPrivateKey = process.env.QUEX_REDBELLY_MAINNET_PRIVATE_KEY ?? "0x0000000000000000000000000000000000000000000000000000000000000001";

const alchemyApiKey = process.env.ALCHEMY_API_KEY ?? "12345";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.22",
    settings: {
      evmVersion: "paris",
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  typechain: {
    outDir: "typechain"
  },
  networks: {
    hardhat: {
      initialDate: "2024-11-05T00:00:00Z"
    },
    redBellyTestnet: {
      chainId: 153,
      url: "https://governors.testnet.redbelly.network",
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    arbitrumSepolia: {
      chainId: 421614,
      url: "https://sepolia-rollup.arbitrum.io/rpc",
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    arbitrumOne: {
      chainId: 42161,
      url: "https://arb1.arbitrum.io/rpc",
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    bscMainnet: {
      chainId: 56,
      url: "https://bsc-dataseed.bnbchain.org",
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    bscTestnet: {
      chainId: 97,
      url: "https://bsc-testnet-dataseed.bnbchain.org",
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    xdcMainnet: {
      chainId: 50,
      url: "https://erpc.xinfin.network",
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    xdcApothem: {
      chainId: 51,
      url: "https://rpc.apothem.network",
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    berachain: {
      chainId: 80094,
      url: "https://rpc.berachain.com/",
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    berachainBepolia: {
      chainId: 80069,
      url: "https://bepolia.rpc.berachain.com/",
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    ethereum: {
      chainId: 1,
      url: `https://eth-mainnet.g.alchemy.com/v2/${alchemyApiKey}`,
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    ethereumSepolia: {
      chainId: 11155111,
      url: `https://eth-sepolia.g.alchemy.com/v2/${alchemyApiKey}`,
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    avalanche: {
      chainId: 43114,
      url: `https://api.avax.network/ext/bc/C/rpc`,
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    avalancheFuji: {
      chainId: 43113,
      url: `https://api.avax-test.network/ext/bc/C/rpc`,
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    celoMainnet: {
      chainId: 42220,
      url: `https://forno.celo.org`,
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    celoAlfajores: {
      chainId: 44787,
      url: `https://alfajores-forno.celo-testnet.org`,
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    redbellyTestnet: {
      chainId: 153,
      url: `https://governors.testnet.redbelly.network`,
      accounts : [quexRedbellyTestnetPrivateKey]
    },
    redbellyMainnet: {
      chainId: 151,
      url: `https://governors.mainnet.redbelly.network`,
      accounts : [quexRedbellyMainnetPrivateKey]
    },
    hederaTestnet: {
      chainId: 296,
      url: `https://testnet.hashio.io/api`,
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    hederaMainnet: {
      chainId: 295,
      url: `https://mainnet.hashio.io/api`,
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    waterfallTestnet9: {
      chainId: 1501869,
      url: `https://rpc.testnet9.waterfall.network/`,
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    }
  },
  gasReporter: {
    enabled: true
  },
  ignition: {
    strategyConfig: {
      create2: {
        salt: "0x19b1da12264f86ca7aa41516ff68f9fbae4086ddca5a5cdf0274984451220c9d"
      }
    }
  }
};

export default config;
