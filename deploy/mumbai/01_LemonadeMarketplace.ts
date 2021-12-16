import { DeployFunction } from 'hardhat-deploy/types';

const FEE_ACCOUNT = '0x951292004e8a18955Cb1095CB72Ca6B01d68336E';
const FEE_VALUE = '200';
const TRUSTED_FORWARDER = '0x9399BB24DBB5C4b782C70c2969F58716Ebbd6a3b';

const deployFunction: DeployFunction = async function ({ deployments: { deploy }, getUnnamedAccounts }) {
  const [from] = await getUnnamedAccounts();

  await deploy('LemonadeMarketplace', {
    args: [FEE_ACCOUNT, FEE_VALUE, TRUSTED_FORWARDER],
    from,
  });
};

export default deployFunction;
