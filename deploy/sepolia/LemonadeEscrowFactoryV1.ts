import type { DeployFunction } from 'hardhat-deploy/types';

const INITIAL_SIGNER = '0xca5AD04d2b42985134BB2E85E78CA6f143787e3B';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getNamedAccounts }) {
  const { deployer: from } = await getNamedAccounts();

  await deploy('LemonadeEscrowFactoryV1', {
    args: [INITIAL_SIGNER, INITIAL_SIGNER, 0],
    from,
    log: true,
  });
};

export default deployFunction;
