import { DeployFunction } from 'hardhat-deploy/types';

const ERC721_NAME = 'Non-Fungible Lemon';
const ERC721_SYMBOL = 'NFL';
const CHILD_CHAIN_MANAGER = '0xb5505a6d998549090530911180f38aC5130101c6';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getUnnamedAccounts }) {
  const [from] = await getUnnamedAccounts();

  await deploy('ERC721Lemonade', {
    args: [ERC721_NAME, ERC721_SYMBOL, CHILD_CHAIN_MANAGER],
    from,
  });
};

export default deployFunction;
