import { ethers } from 'hardhat';

import { deployFunction } from '../../services/ChainlinkRequest';

export default deployFunction({
  chainlinkToken: '0x326c977e6efc84e512bb9c30f76e30c160ed06fb',
  chainlinkOracle: '0x58BdCe3F5f05F51f4B6ceB79aC0d150aed2D5a14',
  jobId: '02ec7f2539534de3b94fac17dbfc8d20',
  fee: ethers.parseEther('0.001'),
  url: 'https://wallet.staging.lemonade.social/chainlink?network=mumbai',
});
