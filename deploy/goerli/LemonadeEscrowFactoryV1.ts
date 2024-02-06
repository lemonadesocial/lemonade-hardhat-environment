import type { DeployFunction } from 'hardhat-deploy/types';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getNamedAccounts }) {
  const { deployer: from } = await getNamedAccounts();

  await deploy('LemonadeEscrowFactoryV1', {
    args: [],
    from,
    log: true,
  });
};

export default deployFunction;
