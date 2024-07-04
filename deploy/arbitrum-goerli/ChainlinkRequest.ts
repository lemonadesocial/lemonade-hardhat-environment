import { ethers } from 'hardhat';

import { deployFunction } from '../../services/ChainlinkRequest';

export default deployFunction({
  chainlinkToken: '0xd14838A68E8AFBAdE5efb411d5871ea0011AFd28',
  chainlinkOracle: '0x0C675daD5ADF0D5CCd360F6ea1fD8b63b6Cf442c',
  jobId: '2c5b789247994d4b9b5bbd001525bceb',
  fee: ethers.parseEther('0.001'),
  url: 'https://wallet.staging.lemonade.social/chainlink?network=arbitrum-goerli',
});
