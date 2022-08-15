import type { DeployFunction } from 'hardhat-deploy/types';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getNamedAccounts }) {
  const { deployer: from } = await getNamedAccounts();

  await deploy('Introspection', {
    from,
    log: true,
  });
};

export default deployFunction;
