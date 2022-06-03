import { DeployFunction } from 'hardhat-deploy/types';

const from = '0x951292004e8a18955Cb1095CB72Ca6B01d68336E';

const FEE_ACCOUNT = from;
const FEE_VALUE = '200';
const TRUSTED_FORWARDER = '0x3D08ce1f9609bB02F47192ff620634d9Eb0E7B56';

const deployFunction: DeployFunction = async function ({ deployments: { deploy } }) {
  await deploy('LemonadeMarketplaceV1Forwardable', {
    args: [FEE_ACCOUNT, FEE_VALUE, TRUSTED_FORWARDER],
    from,
  });
};

export default deployFunction;
