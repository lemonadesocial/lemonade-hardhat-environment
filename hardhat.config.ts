import '@nomiclabs/hardhat-ethers';
import "@nomiclabs/hardhat-etherscan";
import '@nomiclabs/hardhat-waffle';
import 'hardhat-deploy';
import { HardhatUserConfig } from 'hardhat/config';
import * as dotenv from 'dotenv';

dotenv.config();

const mnemonic = process.env.MNEMONIC;

const config: HardhatUserConfig = {
  etherscan: {
    apiKey: {
      polygon: process.env.ETHERSCAN_POLYGON_API_KEY,
      polygonMumbai: process.env.ETHERSCAN_MUMBAI_API_KEY,
    },
  },
  networks: {
    development: {
      url: 'http://127.0.0.1:8545/',
      chainId: 31337,
      accounts,
      deploy: ['deploy/development'],
    },
    ethereum: {
      url: process.env.NETWORK_ETHEREUM_URL,
      chainId: 1,
      accounts: { mnemonic },
      deploy: ['deploy/ethereum'],
    },
    goerli: {
      url: process.env.NETWORK_GOERLI_URL,
      chainId: 5,
      accounts: { mnemonic },
      deploy: ['deploy/goerli'],
    },
    mumbai: {
      url: process.env.NETWORK_MUMBAI_URL,
      chainId: 80001,
      accounts: { mnemonic },
      deploy: ['deploy/mumbai'],
    },
    polygon: {
      url: process.env.NETWORK_POLYGON_URL,
      chainId: 137,
      accounts: { mnemonic },
      deploy: ['deploy/polygon'],
    },
  },
  solidity: "0.8.4",
};

export default config;
