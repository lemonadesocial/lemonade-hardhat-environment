import { ethers } from 'hardhat';

import { deployFunction } from '../../services/ChainlinkRequest';

export default deployFunction({
  chainlinkToken: '0xb0897686c545045aFc77CF20eC7A532E3120E0F1',
  chainlinkOracle: '0x57986329af522966f05315db72Bc834ECb9248B1',
  jobId: '1083ed520f674b8eb5972e7ea7df2bdf',
  fee: ethers.utils.parseEther('0.001'),
  url: 'https://wallet.lemonade.social/chainlink?network=polygon',
});
