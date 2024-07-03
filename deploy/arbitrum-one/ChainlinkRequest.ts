import { ethers } from 'hardhat';

import { deployFunction } from '../../services/ChainlinkRequest';

export default deployFunction({
  chainlinkToken: '0xf97f4df75117a78c1A5a0DBb814Af92458539FB4',
  chainlinkOracle: '0x94f73287BC1667F5472485A7bf2Bfadc639436c8',
  jobId: '25c43bba26e74a1d98d6c2aa4c970d3a',
  fee: ethers.parseEther('0.001'),
  url: 'https://wallet.lemonade.social/chainlink?network=arbitrum-one',
});
