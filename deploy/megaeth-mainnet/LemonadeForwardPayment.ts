import type { DeployFunction } from 'hardhat-deploy/types';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getNamedAccounts }) {
  const { deployer: from } = await getNamedAccounts();

  await deploy('LemonadeForwardPayment', {
    from,
    log: true,
  });
};

deployFunction.tags = ['LemonadeForwardPayment'];

export default deployFunction;
