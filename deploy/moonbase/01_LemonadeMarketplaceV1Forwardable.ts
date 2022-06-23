import { DeployFunction } from 'hardhat-deploy/types';

const from = '0xFB756b44060e426731e54e9F433c43c75ee90d9f';

const FEE_ACCOUNT = from;
const FEE_VALUE = '200';
const TRUSTED_FORWARDER = '0x98dae673b68A0F39B5fD0559F121f081Bc0AE6B8';

const deployFunction: DeployFunction = async function ({ deployments: { deploy } }) {
  await deploy('LemonadeMarketplaceV1Forwardable', {
    args: [FEE_ACCOUNT, FEE_VALUE, TRUSTED_FORWARDER],
    from,
  });
};

export default deployFunction;
