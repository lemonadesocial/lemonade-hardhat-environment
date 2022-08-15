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
  namedAccounts: {
    deployer: process.env.PRIVATE_KEY ? {
      'default':  '0',
    } : {
      'default':      '0xFB756b44060e426731e54e9F433c43c75ee90d9f',
      'aurora':       '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',
      'arbitrum-one': '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',
      'bnb':          '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',
      'ethereum':     '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',
      'polygon':      '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',
      'moonbeam':     '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',
    },
  },
  networks: {
    'arbitrum-one': {
      url: process.env.NETWORK_ARBITRUM_ONE_URL || 'https://arb1.arbitrum.io/rpc',
      chainId: 42161,
      accounts,
      deploy: ['deploy/__all__', 'deploy/arbitrum-one'],
    },
    'arbitrum-rinkeby': {
      url: process.env.NETWORK_ARBITRUM_RINKEBY_URL || 'https://rinkeby.arbitrum.io/rpc',
      chainId: 421611,
      accounts,
      deploy: ['deploy/__all__', 'deploy/arbitrum-rinkeby'],
    },
    'aurora': {
      url: process.env.NETWORK_AURORA_URL || 'https://mainnet.aurora.dev/',
      chainId: 1313161554,
      accounts,
      deploy: ['deploy/__all__', 'deploy/aurora'],
    },
    'aurora-testnet': {
      url: process.env.NETWORK_AURORA_TESTNET_URL || 'https://testnet.aurora.dev/',
      chainId: 1313161555,
      accounts,
      deploy: ['deploy/__all__', 'deploy/aurora-testnet'],
    },
    'bnb': {
      url: process.env.NETWORK_BNB_URL || 'https://bsc-dataseed.binance.org/',
      chainId: 56,
      accounts,
      deploy: ['deploy/__all__', 'deploy/bnb'],
    },
    'bnb-testnet': {
      url: process.env.NETWORK_BNB_TESTNET_URL || 'https://data-seed-prebsc-1-s1.binance.org:8545/',
      chainId: 97,
      accounts,
      deploy: ['deploy/__all__', 'deploy/bnb-testnet'],
    },
    'development': {
      url: 'http://127.0.0.1:8545/',
      chainId: 31337,
      accounts,
      deploy: ['deploy/__all__', 'deploy/development'],
    },
    'ethereum': {
      url: process.env.NETWORK_ETHEREUM_URL || 'https://mainnet.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
      chainId: 1,
      accounts,
      deploy: ['deploy/__all__', 'deploy/ethereum'],
    },
    'mumbai': {
      url: process.env.NETWORK_MUMBAI_URL || 'https://rpc-mumbai.matic.today',
      chainId: 80001,
      accounts,
      deploy: ['deploy/__all__', 'deploy/mumbai'],
    },
    'opal': {
      url: process.env.NETWORK_OPAL_URL || 'https://rpc-opal.unique.network/',
      chainId: 8882,
      accounts,
      deploy: ['deploy/__all__', 'deploy/opal'],
    },
    'polygon': {
      url: process.env.NETWORK_POLYGON_URL || 'https://polygon-rpc.com/',
      chainId: 137,
      accounts,
      deploy: ['deploy/__all__', 'deploy/polygon'],
    },
    'goerli': {
      url: process.env.NETWORK_GOERLI_URL || 'https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
      chainId: 5,
      accounts,
      deploy: ['deploy/__all__', 'deploy/goerli'],
    },
    'moonbase': {
      url: process.env.NETWORK_MOONBASE_URL || 'https://moonbeam-alpha.api.onfinality.io/public',
      chainId: 1287,
      accounts,
      deploy: ['deploy/__all__', 'deploy/moonbase'],
    },
    'moonbeam': {
      url: process.env.NETWORK_MOONBEAM_URL || 'https://moonbeam.api.onfinality.io/public',
      chainId: 1284,
      accounts,
      deploy: ['deploy/__all__', 'deploy/moonbeam'],
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
