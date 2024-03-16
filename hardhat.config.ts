import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import "hardhat-tracer";

import { config as dotenvConfig } from "dotenv";
dotenvConfig();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 5000,
      },
    },
  },
  networks: {
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
      accounts: [process.env.PK as string],
    },
    arbsep: {
      url: `https://arb-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
      accounts: [process.env.PK as string],
    },
  },
  namedAccounts: {
    deployer: {
      default: 0, // here this will by default take the first account as deployer
    },
  },
};

export default config;
