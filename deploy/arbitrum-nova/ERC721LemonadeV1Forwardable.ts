import type { DeployFunction } from 'hardhat-deploy/types';

const ERC721_NAME = 'Non-Fungible Lemon';
const ERC721_SYMBOL = 'NFL';
const TRUSTED_FORWARDER = '0xfe0fa3C06d03bDC7fb49c892BbB39113B534fB57';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getNamedAccounts }) {
  const { deployer: from } = await getNamedAccounts();

  await deploy('ERC721LemonadeV1Forwardable', {
    args: [ERC721_NAME, ERC721_SYMBOL, TRUSTED_FORWARDER],
    from,
    log: true,
  });
};

export default deployFunction;
