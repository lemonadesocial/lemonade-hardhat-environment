import type { DeployFunction } from 'hardhat-deploy/types';

const ERC721_NAME = 'Non-Fungible Lemon';
const ERC721_SYMBOL = 'NFL';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getNamedAccounts }) {
  const { deployer: from } = await getNamedAccounts();

  await deploy('ERC721LemonadeV1', {
    args: [ERC721_NAME, ERC721_SYMBOL],
    from,
    log: true,
  });
};

export default deployFunction;
