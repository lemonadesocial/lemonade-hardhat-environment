import { DeployFunction } from 'hardhat-deploy/types';
import { ethers } from 'hardhat';

const FEE_MAKER = '0x951292004e8a18955Cb1095CB72Ca6B01d68336E';
const FEE_RATIO = ethers.utils.parseEther('0.02');

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getUnnamedAccounts }) {
  const [from] = await getUnnamedAccounts();

  await deploy('LemonadeMarketplace', {
    args: [FEE_MAKER, FEE_RATIO],
    from,
  });
};

export default deployFunction;
