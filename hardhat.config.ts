import 'hardhat-deploy';
import { HardhatUserConfig } from 'hardhat/config';
import * as dotenv from 'dotenv';

dotenv.config();

const config: HardhatUserConfig = {
  networks: {
    mumbai: {
      live: true,
      url: process.env.NETWORKS_MUMBAI_URL,
      chainId: 80001,
      accounts: { mnemonic: process.env.MNEMONIC },
    },
  },
  solidity: "0.8.4",
};

export default config;
