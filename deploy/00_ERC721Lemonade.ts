import { DeployFunction } from 'hardhat-deploy/types';

const ERC721Lemonade_NAME = 'Non-Fungible Lemon';
const ERC721Lemonade_SYMBOL = 'NFL';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getUnnamedAccounts }) {
  const [from] = await getUnnamedAccounts();

  await deploy('ERC721Lemonade', {
    args: [ERC721Lemonade_NAME, ERC721Lemonade_SYMBOL],
    from,
  });
};

export default deployFunction;
