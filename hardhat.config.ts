import '@nomiclabs/hardhat-ethers';
import "@nomiclabs/hardhat-etherscan";
import '@nomiclabs/hardhat-waffle';
import 'hardhat-deploy';
import { HardhatUserConfig } from 'hardhat/config';
import * as dotenv from 'dotenv';

dotenv.config();

const accounts =
  process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] :
  process.env.MNEMONIC ? { mnemonic: process.env.MNEMONIC } :
  undefined;

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
      accounts,
      deploy: ['deploy/ethereum'],
    },
    mumbai: {
      url: process.env.NETWORK_MUMBAI_URL,
      chainId: 80001,
      accounts,
      deploy: ['deploy/mumbai'],
    },
    polygon: {
      url: process.env.NETWORK_POLYGON_URL,
      chainId: 137,
      accounts,
      deploy: ['deploy/polygon'],
    },
    rinkeby: {
      url: process.env.NETWORK_RINKEBY_URL,
      chainId: 4,
      accounts,
      deploy: ['deploy/rinkeby'],
    },
    moonbase: {
      url: process.env.NETWORK_MOONBASE_URL,
      chainId: 1287,
      accounts,
      deploy: ['deploy/moonbase'],
    },
    moonbeam: {
      url: process.env.NETWORK_MOONBEAM_URL,
      chainId: 1284,
      accounts,
      deploy: ['deploy/moonbeam'],
    },
  },
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
      },
    },
  },
};

export default config;
