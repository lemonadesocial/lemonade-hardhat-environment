import type { DeployFunction } from 'hardhat-deploy/types';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getNamedAccounts }) {
  const { deployer: from } = await getNamedAccounts();

  await deploy('GenericFactory', {
    from,
    log: true,
  });
};

deployFunction.tags = ['GenericFactory'];

export default deployFunction;
