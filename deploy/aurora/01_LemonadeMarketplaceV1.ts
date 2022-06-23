import { DeployFunction } from 'hardhat-deploy/types';

const from = '0x951292004e8a18955Cb1095CB72Ca6B01d68336E';

const FEE_ACCOUNT = from;
const FEE_VALUE = '200';

const deployFunction: DeployFunction = async function ({ deployments: { deploy } }) {
  await deploy('LemonadeMarketplaceV1', {
    args: [FEE_ACCOUNT, FEE_VALUE],
    from,
  });
};

export default deployFunction;
