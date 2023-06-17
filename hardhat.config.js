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
      url: process.env.POLYGON_MUMBAI_RPC_URL
    },
    polygon: {
      url: process.env.POLYGON_RPC_URL
    },
    fvm_calibration: {
      url: process.env.FVM_CALIBRATION_RPC_URL
    },
    fvm_mainnet: {
      url: process.env.FVM_MAINNET_RPC_URL
    },
    ethereum: {
      url: process.env.ETHEREUM_RPC_URL
    },
    goerli: {
      url: process.env.GOERLI_RPC_URL
    }
  },
  etherscan: {
    apiKey: {
      polygonMumbai: process.env.API_KEY_POLYGONSCAN,
      polygon: process.env.API_KEY_POLYGONSCAN,
      mainnet: process.env.API_KEY_ETHERSCAN,
      goerli: process.env.API_KEY_ETHERSCAN,
    }
  },
  contractSizer: {
    runOnCompile: true
  }
};
