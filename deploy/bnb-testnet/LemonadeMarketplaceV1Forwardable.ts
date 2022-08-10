import type { DeployFunction } from 'hardhat-deploy/types';

const FEE_ACCOUNT = '0xFB756b44060e426731e54e9F433c43c75ee90d9f';
const FEE_VALUE = '200';
const TRUSTED_FORWARDER = '0x61456BF1715C1415730076BB79ae118E806E74d2';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getNamedAccounts }) {
  const { deployer: from } = await getNamedAccounts();

  await deploy('LemonadeMarketplaceV1Forwardable', {
    args: [FEE_ACCOUNT, FEE_VALUE, TRUSTED_FORWARDER],
    from,
    log: true,
  });
};

export default deployFunction;
