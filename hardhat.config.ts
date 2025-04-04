import '@matterlabs/hardhat-zksync-deploy';
import '@matterlabs/hardhat-zksync-solc';
import '@matterlabs/hardhat-zksync-upgradable';
import '@nomicfoundation/hardhat-chai-matchers';
import '@nomicfoundation/hardhat-toolbox-viem';
import '@openzeppelin/hardhat-upgrades';
import * as dotenv from 'dotenv';
import 'hardhat-contract-sizer';
import 'hardhat-deploy';
import { HardhatUserConfig } from 'hardhat/config';

dotenv.config();

const accounts =
  process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] :
    process.env.MNEMONIC ? { mnemonic: process.env.MNEMONIC } :
      undefined;

const config: HardhatUserConfig = {
  etherscan: {
    apiKey: {
      arbitrumOne: process.env.ETHERSCAN_ARBITRUM_API_KEY || '',
      arbitrumGoerli: process.env.ETHERSCAN_ARBITRUM_API_KEY || '',
      polygon: process.env.ETHERSCAN_POLYGON_API_KEY || '',
      polygonMumbai: process.env.ETHERSCAN_POLYGON_API_KEY || '',
    },
  },
  // platform: {
  //   apiKey: process.env.PLATFORM_API_KEY || '',
  //   apiSecret: process.env.PLATFORM_API_SECRET || '',
  //   usePlatformDeploy: false,
  // },
  namedAccounts: {
    deployer: process.env.PRIVATE_KEY ? {
      'default': 0,
    } : {
      'default': '0xFB756b44060e426731e54e9F433c43c75ee90d9f',
      'aurora': '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',
      'arbitrum-nova': '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',
      'arbitrum-one': '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',
      'astar': '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',
      'avalanche': '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',
      'base': '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',
      'bnb': '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',
      'celo': '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',
      'development': '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
      'ethereum': '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',
      'gnosis': '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',
      'optimism': '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',
      'polygon': '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',
      'moonbeam': '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',
      'unique': '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',
      'zero': '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',
    },
  },
  networks: {
    'arbitrum-goerli': {
      url: process.env.NETWORK_ARBITRUM_GOERLI_URL || 'https://goerli-rollup.arbitrum.io/rpc',
      chainId: 421613,
      accounts,
      deploy: ['deploy/__all__', 'deploy/arbitrum-goerli'],
    },
    'arbitrum-nova': {
      url: process.env.NETWORK_ARBITRUM_NOVA_URL || 'https://nova.arbitrum.io/rpc',
      chainId: 42170,
      accounts,
      deploy: ['deploy/__all__', 'deploy/arbitrum-nova'],
    },
    'arbitrum-one': {
      url: process.env.NETWORK_ARBITRUM_ONE_URL || 'https://arb1.arbitrum.io/rpc',
      chainId: 42161,
      accounts,
      deploy: ['deploy/__all__', 'deploy/arbitrum-one'],
    },
    'arbitrum-sepolia': {
      url: process.env.NETWORK_ARBITRUM_SEPOLIA_URL || 'https://sepolia-rollup.arbitrum.io/rpc',
      chainId: 421614,
      accounts,
      deploy: ['deploy/__all__', 'deploy/arbitrum-sepolia'],
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
    'astar': {
      url: process.env.NETWORK_ASTAR_URL || 'https://evm.astar.network/',
      chainId: 592,
      accounts,
      deploy: ['deploy/__all__', 'deploy/astar'],
    },
    'avalanche': {
      url: process.env.NETWORK_AVALANCHE_URL || 'https://api.avax.network/ext/bc/C/rpc',
      chainId: 43114,
      accounts,
      deploy: ['deploy/__all__', 'deploy/avalanche'],
    },
    'base': {
      url: process.env.NETWORK_BASE_URL || 'https://mainnet.base.org/',
      chainId: 8453,
      accounts,
      deploy: ['deploy/__all__', 'deploy/base'],
    },
    'base-sepolia': {
      url: process.env.NETWORK_BASE_SEPOLIA_URL || 'https://sepolia.base.org/',
      chainId: 84532,
      accounts,
      deploy: ['deploy/__all__', 'deploy/base-sepolia'],
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
    'celo': {
      url: process.env.NETWORK_CELO_URL || 'https://forno.celo.org/',
      chainId: 42220,
      accounts,
      deploy: ['deploy/__all__', 'deploy/celo'],
    },
    'cyber-testnet': {
      url: process.env.NETWORK_CYBER_TESTNET_URL || 'https://cyber-testnet.alt.technology/',
      chainId: 111557560,
      accounts,
      deploy: ['deploy/__all__', 'deploy/cyber-testnet'],
    },
    'cyber': {
      url: process.env.NETWORK_CYBER_URL || 'https://cyber.alt.technology/',
      chainId: 7560,
      accounts,
      deploy: ['deploy/__all__', 'deploy/cyber'],
    },
    'development': {
      url: 'http://127.0.0.1:8545/',
      chainId: 31337,
      accounts: ['0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'],
      deploy: ['deploy/__all__', 'deploy/development'],
    },
    'ethereum': {
      url: process.env.NETWORK_ETHEREUM_URL || 'https://mainnet.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
      chainId: 1,
      accounts,
      deploy: ['deploy/__all__', 'deploy/ethereum'],
    },
    'exp-testnet': {
      url: process.env.NETWORK_EXP_TESTNET_URL || 'https://rpc0-testnet.expchain.ai',
      chainId: 18880,
      accounts,
      deploy: ['deploy/__all__', 'deploy/exp-testnet'],
    },
    'gnosis': {
      url: process.env.NETWORK_GNOSIS_URL || 'https://rpc.gnosischain.com/',
      chainId: 100,
      accounts,
      deploy: ['deploy/__all__', 'deploy/gnosis'],
    },
    'mumbai': {
      url: process.env.NETWORK_MUMBAI_URL || 'https://rpc-mumbai.maticvigil.com/',
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
    'optimism': {
      url: process.env.NETWORK_OPTIMISM_URL || 'https://mainnet.optimism.io',
      chainId: 10,
      accounts,
      deploy: ['deploy/__all__', 'deploy/optimism'],
    },
    'optimism-goerli': {
      url: process.env.NETWORK_OPTIMISM_GOERLI_URL || 'https://goerli.optimism.io',
      chainId: 420,
      accounts,
      deploy: ['deploy/__all__', 'deploy/optimism-goerli'],
    },
    'polygon': {
      url: process.env.NETWORK_POLYGON_URL || 'https://rpc-mainnet.maticvigil.com/',
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
    'linea': {
      url: process.env.NETWORK_LINEA_URL || 'https://rpc.linea.build',
      chainId: 59144,
      accounts,
      deploy: ['deploy/__all__', 'deploy/linea'],
    },
    'lisk': {
      url: process.env.NETWORK_LISK_URL || 'https://rpc.api.lisk.com',
      chainId: 1135,
      accounts,
      deploy: ['deploy/__all__', 'deploy/lisk'],
    },
    'lisk-sepolia': {
      url: process.env.NETWORK_LISK_SEPOLIA_URL || 'https://rpc.sepolia-api.lisk.com',
      chainId: 4202,
      accounts,
      deploy: ['deploy/__all__', 'deploy/lisk-sepolia'],
    },
    'mantle': {
      url: process.env.NETWORK_MANTLE_URL || 'https://rpc.mantle.xyz',
      chainId: 5000,
      accounts,
      deploy: ['deploy/__all__', 'deploy/mantle'],
    },
    'mantle-sepolia': {
      url: process.env.NETWORK_MANTLE_SEPOLIA_URL || 'https://rpc.sepolia.mantle.xyz',
      chainId: 5003,
      accounts,
      deploy: ['deploy/__all__', 'deploy/mantle-sepolia'],
    },
    'megaeth-testnet': {
      url: process.env.NETWORK_MEGAETH_TESTNET_URL || 'https://carrot.megaeth.com/rpc',
      chainId: 6342,
      accounts,
      deploy: ['deploy/__all__', 'deploy/megaeth-testnet'],
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
    'scroll': {
      url: process.env.NETWORK_SCROLL_URL || 'https://rpc.scroll.io',
      chainId: 534352,
      accounts,
      deploy: ['deploy/__all__', 'deploy/scroll'],
    },
    'scroll-sepolia': {
      url: process.env.NETWORK_SCROLL_SEPOLIA_URL || 'https://sepolia-rpc.scroll.io',
      chainId: 534351,
      accounts,
      deploy: ['deploy/__all__', 'deploy/scroll-sepolia'],
    },
    'sepolia': {
      url: process.env.NETWORK_SEPOLIA_URL || 'https://ethereum-sepolia.publicnode.com/',
      chainId: 11155111,
      accounts,
      deploy: ['deploy/__all__', 'deploy/sepolia'],
    },
    'sei': {
      url: process.env.NETWORK_SEI_URL || 'https://evm-rpc.sei-apis.com',
      chainId: 1329,
      accounts,
      deploy: ['deploy/__all__', 'deploy/sei'],
    },
    'sei-testnet': {
      url: process.env.NETWORK_SEI_TESTNET_URL || 'https://evm-rpc-testnet.sei-apis.com',
      chainId: 1328,
      accounts,
      deploy: ['deploy/__all__', 'deploy/sei-testnet'],
    },
    'optimism-sepolia': {
      url: process.env.NETWORK_OPTIMISM_SEPOLIA_URL || 'https://sepolia.optimism.io/',
      chainId: 11155420,
      accounts,
      deploy: ['deploy/__all__', 'deploy/optimism-sepolia'],
    },
    'unique': {
      url: process.env.NETWORK_UNIQUE_URL || 'https://rpc.unique.network/',
      chainId: 8880,
      accounts,
      deploy: ['deploy/__all__', 'deploy/unique'],
    },
    'world': {
      url: process.env.NETWORK_WORLD_URL || 'https://worldchain-mainnet.g.alchemy.com/public',
      chainId: 480,
      accounts,
      deploy: ['deploy/__all__', 'deploy/world'],
    },
    'zero': {
      url: process.env.NETWORK_ZERO_URL || 'https://zero.alt.technology/',
      chainId: 4000003,
      accounts,
      deploy: ['deploy/__all__', 'deploy/zero'],
    },
    'zk-sepolia': {
      url: process.env.NETWORK_ZK_SEPOLIA_URL || 'https://sepolia.era.zksync.dev',
      chainId: 300,
      zksync: true,
      forceDeploy: false,
      ethNetwork: "sepolia",
      accounts,
      deploy: ['deploy/__all-zk__', 'deploy/zk-sepolia'],
    },
    'zk-link-nova': {
      url: process.env.NETWORK_ZK_LINK_NOVA_URL || 'https://rpc.zklink.io',
      chainId: 810180,
      zksync: true,
      forceDeploy: false,
      ethNetwork: "mainnet",
      accounts,
      deploy: ['deploy/__all-zk__', 'deploy/zk-link-nova'],
    }
  },
  zksolc: {
    version: 'latest',
    compilerSource: 'binary',
    settings: {
      contractsToCompile: ['Introspection', 'AccessRegistry', 'PaymentConfigRegistry', 'LemonadeRelayPayment'],
    }
  },
  solidity: {
    compilers: [
      {
        version: '0.7.0',
        settings: {
          optimizer: {
            enabled: true,
          },
        },
      },
      {
        version: '0.8.4',
        settings: {
          optimizer: {
            enabled: true,
          },
        },
      },
    ],
    overrides: {
      'contracts/passport/DrawerV1FunUnitedNations.sol': {
        version: '0.8.4',
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            details: {
              yulDetails: {
                optimizerSteps: 'u',
              },
            },
          },
        },
      },
      'contracts/passport/DrawerV1HerNation.sol': {
        version: '0.8.4',
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            details: {
              yulDetails: {
                optimizerSteps: 'u',
              },
            },
          },
        },
      },
    },
  },
};

export default config;
