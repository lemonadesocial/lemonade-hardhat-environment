import { ethers } from 'hardhat';
import type { DeployFunction } from 'hardhat-deploy/types';

const COLLECTION_HELPERS = '0x6c4e9fe1ae37a41e93cee429e8e1881abdcbb54f';
const COLLECTION_NAME = 'Non-Fungible Lemon';
const COLLECTION_DESCRIPTION = 'Non-Fungible Lemon';
const COLLECTION_TOKEN_PREFIX = 'NFL';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getNamedAccounts }) {
  const { deployer: from } = await getNamedAccounts();

  await deploy('LemonadeUniqueCollectionV1', {
    args: [COLLECTION_HELPERS, COLLECTION_NAME, COLLECTION_DESCRIPTION, COLLECTION_TOKEN_PREFIX],
    from,
    log: true,
    value: ethers.utils.parseEther('2'),
  });
};

export default deployFunction;
