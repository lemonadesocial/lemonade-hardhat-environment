import { DeployFunction } from 'hardhat-deploy/types';

const ERC721_NAME = 'Non-Fungible Lemon';
const ERC721_SYMBOL = 'NFL';
const TRUSTED_FORWARDER = '0x86C80a8aa58e0A4fa09A69624c31Ab2a6CAD56b8';
const CHILD_CHAIN_MANAGER = '0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getUnnamedAccounts }) {
  const [from] = await getUnnamedAccounts();

  await deploy('ERC721Lemonade', {
    args: [ERC721_NAME, ERC721_SYMBOL, TRUSTED_FORWARDER, CHILD_CHAIN_MANAGER],
    from,
  });
};

export default deployFunction;
