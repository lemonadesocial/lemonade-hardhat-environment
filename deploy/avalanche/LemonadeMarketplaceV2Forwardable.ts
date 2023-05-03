import type { DeployFunction } from 'hardhat-deploy/types';

const FEE_ACCOUNT = '0x951292004e8a18955Cb1095CB72Ca6B01d68336E';
const FEE_VALUE = '200';
const TRUSTED_FORWARDER = '0x64CD353384109423a966dCd3Aa30D884C9b2E057';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getNamedAccounts }) {
  const { deployer: from } = await getNamedAccounts();

  await deploy('LemonadeMarketplaceV2Forwardable', {
    args: [FEE_ACCOUNT, FEE_VALUE, TRUSTED_FORWARDER],
    from,
    log: true,
  });
};

export default deployFunction;
