import { ethers } from 'hardhat';
import { DeployFunction } from 'hardhat-deploy/types';

const from = '0xFB756b44060e426731e54e9F433c43c75ee90d9f';

const COLLECTION_HELPERS = '0x6c4e9fe1ae37a41e93cee429e8e1881abdcbb54f';
const COLLECTION_NAME = 'Non-Fungible Lemon';
const COLLECTION_DESCRIPTION = 'Non-Fungible Lemon';
const COLLECTION_TOKEN_PREFIX = 'NFL';

const deployFunction: DeployFunction = async function ({ deployments: { deploy } }) {
  await deploy('LemonadeUniqueCollectionV1', {
    args: [COLLECTION_HELPERS, COLLECTION_NAME, COLLECTION_DESCRIPTION, COLLECTION_TOKEN_PREFIX],
    from,
    value: ethers.utils.parseEther('3'),
  });
};

export default deployFunction;
