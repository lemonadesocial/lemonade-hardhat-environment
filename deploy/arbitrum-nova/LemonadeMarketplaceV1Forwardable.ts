import type { DeployFunction } from 'hardhat-deploy/types';

const FEE_ACCOUNT = '0x951292004e8a18955Cb1095CB72Ca6B01d68336E';
const FEE_VALUE = '200';
const TRUSTED_FORWARDER = '0xfe0fa3C06d03bDC7fb49c892BbB39113B534fB57';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getNamedAccounts }) {
  const { deployer: from } = await getNamedAccounts();

  await deploy('LemonadeMarketplaceV1Forwardable', {
    args: [FEE_ACCOUNT, FEE_VALUE, TRUSTED_FORWARDER],
    from,
    log: true,
  });
};

export default deployFunction;
