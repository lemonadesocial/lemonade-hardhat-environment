import { DeployFunction } from 'hardhat-deploy/types';

const from = '0xFB756b44060e426731e54e9F433c43c75ee90d9f';

const ERC721_NAME = 'Non-Fungible Lemon';
const ERC721_SYMBOL = 'NFL';
const TRUSTED_FORWARDER = '0x98dae673b68A0F39B5fD0559F121f081Bc0AE6B8';

const deployFunction: DeployFunction = async function ({ deployments: { deploy } }) {
  await deploy('ERC721LemonadeV1Forwardable', {
    args: [ERC721_NAME, ERC721_SYMBOL, TRUSTED_FORWARDER],
    from,
  });
};

export default deployFunction;
