import type { DeployFunction } from 'hardhat-deploy/types';

const ERC721_NAME = 'Non-Fungible Lemon';
const ERC721_SYMBOL = 'NFL';
const TRUSTED_FORWARDER = '0x9399BB24DBB5C4b782C70c2969F58716Ebbd6a3b';
const TRUSTED_OPERATOR = '0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getNamedAccounts }) {
  const { deployer: from } = await getNamedAccounts();

  await deploy('ERC721LemonadeV1Polygon', {
    args: [ERC721_NAME, ERC721_SYMBOL, TRUSTED_FORWARDER, TRUSTED_OPERATOR],
    from,
    log: true,
  });
};

export default deployFunction;
