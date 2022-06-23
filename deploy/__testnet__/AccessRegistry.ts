import { DeployFunction } from 'hardhat-deploy/types';

const from = '0xFB756b44060e426731e54e9F433c43c75ee90d9f';

const deployFunction: DeployFunction = async function ({ deployments: { deploy } }) {
  await deploy('AccessRegistry', { from });
};

export default deployFunction;
