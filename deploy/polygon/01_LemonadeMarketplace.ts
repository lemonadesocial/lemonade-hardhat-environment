import { DeployFunction } from 'hardhat-deploy/types';

const FEE_ACCOUNT = '0x951292004e8a18955Cb1095CB72Ca6B01d68336E';
const FEE_VALUE = '200';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getUnnamedAccounts }) {
  const [from] = await getUnnamedAccounts();

  await deploy('LemonadeMarketplace', {
    args: [FEE_ACCOUNT, FEE_VALUE],
    from,
  });
};

export default deployFunction;
