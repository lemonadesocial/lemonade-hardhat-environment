import { DeployFunction } from 'hardhat-deploy/types';

const ERC721_NAME = 'Non-Fungible Lemon';
const ERC721_SYMBOL = 'NFL';
const PROXY_REGISTRY_ADDRESS = '0xf57b2c51ded3a29e6891aba85459d600256cf317';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getUnnamedAccounts }) {
  const [from] = await getUnnamedAccounts();

  await deploy('ERC721LemonadeV1Ethereum', {
    args: [ERC721_NAME, ERC721_SYMBOL, PROXY_REGISTRY_ADDRESS],
    from,
  });
};

export default deployFunction;
