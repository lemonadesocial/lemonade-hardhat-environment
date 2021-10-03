import 'hardhat-deploy';
import { HardhatUserConfig } from 'hardhat/config';
import * as dotenv from 'dotenv';

dotenv.config();

const mnemonic = process.env.MNEMONIC;

const config: HardhatUserConfig = {
  networks: {
    mumbai: {
      url: process.env.NETWORK_MUMBAI_URL,
      chainId: 80001,
      accounts: { mnemonic },
    },
    polygon: {
      url: process.env.NETWORK_POLYGON_URL,
      chainId: 137,
      accounts: { mnemonic },
    },
  },
  solidity: "0.8.4",
};

export default config;
