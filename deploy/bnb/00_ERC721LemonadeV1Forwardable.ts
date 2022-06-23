import { DeployFunction } from 'hardhat-deploy/types';

const from = '0x951292004e8a18955Cb1095CB72Ca6B01d68336E';

const ERC721_NAME = 'Non-Fungible Lemon';
const ERC721_SYMBOL = 'NFL';
const TRUSTED_FORWARDER = '0x86C80a8aa58e0A4fa09A69624c31Ab2a6CAD56b8';

const deployFunction: DeployFunction = async function ({ deployments: { deploy } }) {
  await deploy('ERC721LemonadeV1Forwardable', {
    args: [ERC721_NAME, ERC721_SYMBOL, TRUSTED_FORWARDER],
    from,
  });
};

export default deployFunction;
