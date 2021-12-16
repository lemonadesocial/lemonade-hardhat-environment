import { DeployFunction } from 'hardhat-deploy/types';

const ERC721_NAME = 'Non-Fungible Lemon';
const ERC721_SYMBOL = 'NFL';
const TRUSTED_FORWARDER = '0x9399BB24DBB5C4b782C70c2969F58716Ebbd6a3b';
const CHILD_CHAIN_MANAGER = '0xb5505a6d998549090530911180f38aC5130101c6';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getUnnamedAccounts }) {
  const [from] = await getUnnamedAccounts();

  await deploy('ERC721Lemonade', {
    args: [ERC721_NAME, ERC721_SYMBOL, TRUSTED_FORWARDER, CHILD_CHAIN_MANAGER],
    from,
  });
};

export default deployFunction;
