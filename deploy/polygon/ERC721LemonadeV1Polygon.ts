import type { DeployFunction } from 'hardhat-deploy/types';

const ERC721_NAME = 'Non-Fungible Lemon';
const ERC721_SYMBOL = 'NFL';
const TRUSTED_FORWARDER = '0x86C80a8aa58e0A4fa09A69624c31Ab2a6CAD56b8';
const TRUSTED_OPERATOR = '0x58807baD0B376efc12F5AD86aAc70E78ed67deaE';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getNamedAccounts }) {
  const { deployer: from } = await getNamedAccounts();

  await deploy('ERC721LemonadeV1Polygon', {
    args: [ERC721_NAME, ERC721_SYMBOL, TRUSTED_FORWARDER, TRUSTED_OPERATOR],
    from,
    log: true,
  });
};

export default deployFunction;
