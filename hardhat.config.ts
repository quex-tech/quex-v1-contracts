import { HardhatUserConfig, vars } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";
import "hardhat-gas-reporter";

const quexPrivateKey = vars.get("QUEX_PRIVATE_KEY")

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
      accounts : [quexPrivateKey]
    },
    arbitrumSepolia: {
      chainId: 421614,
      url: "https://sepolia-rollup.arbitrum.io/rpc",
      accounts : [quexPrivateKey]
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
