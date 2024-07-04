import type { DeployFunction } from 'hardhat-deploy/types';

const deployFunction: DeployFunction = async function ({ deployer }) {
  await deployer.deploy('Introspection');
};

export default deployFunction;
