import { DeployFunction } from 'hardhat-deploy/types';

const from = '0xFB756b44060e426731e54e9F433c43c75ee90d9f';

const ERC721_NAME = 'Non-Fungible Lemon';
const ERC721_SYMBOL = 'NFL';
const PROXY_REGISTRY_ADDRESS = '0x1E525EEAF261cA41b809884CBDE9DD9E1619573A';

const deployFunction: DeployFunction = async function ({ deployments: { deploy } }) {
  await deploy('ERC721LemonadeV1Ethereum', {
    args: [ERC721_NAME, ERC721_SYMBOL, PROXY_REGISTRY_ADDRESS],
    from,
  });
};

export default deployFunction;
