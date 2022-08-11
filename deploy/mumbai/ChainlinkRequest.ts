import { ethers } from 'hardhat';

import { deployFunction } from '../../services/ChainlinkRequest';

export default deployFunction({
  chainlinkToken: '0x326c977e6efc84e512bb9c30f76e30c160ed06fb',
  chainlinkOracle: '0xB51Dc0a6d7a532F7FE8909D631875b13999eE8d1',
  jobId: '6b9f2de7cc3a4d4b8e98ab63fc8e9026',
  fee: ethers.utils.parseEther('0.01'),
  url: 'https://backend.staging.lemonade.social/chainlink?network=mumbai',
});
