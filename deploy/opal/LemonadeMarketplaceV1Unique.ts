import type { DeployFunction } from 'hardhat-deploy/types';

const FEE_ACCOUNT = '0xFB756b44060e426731e54e9F433c43c75ee90d9f';
const FEE_VALUE = '200';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getNamedAccounts }) {
  const { deployer: from } = await getNamedAccounts();

  await deploy('LemonadeMarketplaceV1Unique', {
    args: [FEE_ACCOUNT, FEE_VALUE],
    from,
    log: true,
  });
};

export default deployFunction;
