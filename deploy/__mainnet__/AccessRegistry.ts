import { DeployFunction } from 'hardhat-deploy/types';

const from = '0x951292004e8a18955Cb1095CB72Ca6B01d68336E';

const deployFunction: DeployFunction = async function ({ deployments: { deploy } }) {
  await deploy('AccessRegistry', { from });
};

export default deployFunction;
