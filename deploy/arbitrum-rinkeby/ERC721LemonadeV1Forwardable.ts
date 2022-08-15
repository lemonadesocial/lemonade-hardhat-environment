import type { DeployFunction } from 'hardhat-deploy/types';

const ERC721_NAME = 'Non-Fungible Lemon';
const ERC721_SYMBOL = 'NFL';
const TRUSTED_FORWARDER = '0x67454E169d613a8e9BA6b06af2D267696EAaAf41';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getNamedAccounts }) {
  const { deployer: from } = await getNamedAccounts();

  await deploy('ERC721LemonadeV1Forwardable', {
    args: [ERC721_NAME, ERC721_SYMBOL, TRUSTED_FORWARDER],
    from,
    log: true,
  });
};

export default deployFunction;
