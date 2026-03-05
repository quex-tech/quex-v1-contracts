import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";
import "hardhat-gas-reporter";
import dotenv from "dotenv";

dotenv.config();

const deploySalt = process.env.IGNITION_SALT ?? "0x29b1da12264f86ca7aa41516ff68f9fbae4086ddca5a5cdf0274984451220c9d";

const quexDeployerPrivateKey = process.env.QUEX_DEPLOYER_PRIVATE_KEY ?? "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
const quexManagerPrivateKey = process.env.QUEX_MANAGER_PRIVATE_KEY ?? "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";

const quexRedbellyTestnetPrivateKey = process.env.QUEX_REDBELLY_TESTNET_PRIVATE_KEY ?? "0x0000000000000000000000000000000000000000000000000000000000000001";
const quexRedbellyMainnetPrivateKey = process.env.QUEX_REDBELLY_MAINNET_PRIVATE_KEY ?? "0x0000000000000000000000000000000000000000000000000000000000000001";

const alchemyApiKey = process.env.ALCHEMY_API_KEY ?? "12345";

const etherscanApiKey = process.env.ETHERSCAN_API_KEY ?? "12345";

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
    arbitrumSepolia: {
      chainId: 421614,
      url: `https://arb-sepolia.g.alchemy.com/v2/${alchemyApiKey}`,
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    arbitrumOne: {
      chainId: 42161,
      url: "https://arb1.arbitrum.io/rpc",
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
    waterfallTestnet9: {
      chainId: 1501869,
      url: `https://rpc.testnet9.waterfall.network/`,
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    waterfallMainnet: {
      chainId: 181,
      url: `https://rpc.waterfall.network/`,
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    baseSepolia: {
      chainId: 84532,
      url: `https://sepolia.base.org`,
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    baseMainnet: {
      chainId: 8453,
      url: `https://mainnet.base.org`,
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    kasplexTestnet: {
      chainId: 167012,
      url: `https://rpc.kasplextest.xyz`,
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    morphMainnet: {
      chainId: 2818,
      url: `https://rpc-quicknode.morphl2.io`,
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    morphHolesky: {
      chainId: 2810,
      url: `https://rpc-quicknode-holesky.morphl2.io`,
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    "0gTestnet": {
      chainId: 16601,
      url: `https://evmrpc-testnet.0g.ai`,
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    igraGalleonTestnet: {
      chainId: 38836,
      url: `https://galleon-testnet.igralabs.com:8545`,
      accounts: [quexDeployerPrivateKey, quexManagerPrivateKey],
      ignition: {
        gasPrice: 3000000000000n,
        maxPriorityFeePerGas: 3000000000000n,
        maxFeePerGas: 3000000000000n,
      },
      gasPrice: 3000000000000,
      gas: 5000000,
    },
    "0gMainnet": {
      chainId: 16661,
      url: `http://evmrpc.0g.ai/`,
      accounts : [quexDeployerPrivateKey, quexManagerPrivateKey]
    },
    igraMainnet: {
      chainId: 38833,
      url: `https://rpc.igralabs.com:8545`,
      accounts: [quexDeployerPrivateKey, quexManagerPrivateKey],
      ignition: {
        gasPrice: 1000000000000n,
        maxPriorityFeePerGas: 1000000000000n,
        maxFeePerGas: 1000000000000n,
      },
      gasPrice: 1000000000000,
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
  },
  gasReporter: {
    enabled: true
  },
  ignition: {
    strategyConfig: {
      create2: {
        salt: deploySalt
      }
    }
  },
  etherscan: {
    apiKey: etherscanApiKey,
    customChains: [
      {
        network: "xdcMainnet",
        chainId: 50,
        urls: {
          apiURL: "https://erpc.xinfin.network/api",
          browserURL: "https://xdcscan.com/"
        }
      },
      {
        network: "xdcApothem",
        chainId: 51,
        urls: {
          apiURL: "https://rpc.apothem.network/api",
          browserURL: "https://testnet.xdcscan.com"
        }
      }
    ]
  }
};

export default config;
