require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require('hardhat-contract-sizer');
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  gasReporter: {
    enabled: true
  },
  networks: {
    polygonMumbai: {
      url: process.env.POLYGON_MUMBAI_RPC_URL,
      accounts: [process.env.PRIVATE_KEY]
    },
    polygon: {
      url: process.env.POLYGON_RPC_URL,
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: {
      polygonMumbai: process.env.API_KEY_POLYGONSCAN,
      polygon: process.env.API_KEY_POLYGONSCAN,
    }
  },
  contractSizer: {
    runOnCompile: true
  }
};
