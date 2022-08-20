import { ethers } from 'hardhat';
import type { DeployFunction } from 'hardhat-deploy/types';

interface Config {
  authorizedSenders: string[];
  chainlinkToken: string;
}

export function deployFunction(config: Config): DeployFunction {
  return async function ({ deployments: { deploy }, getNamedAccounts }) {
    const { deployer: from } = await getNamedAccounts();

    const deployResult = await deploy('Operator', {
      args: [config.chainlinkToken, from],
      from,
      log: true,
    });

    const contract = await ethers.getContractAt(
      deployResult.abi,
      deployResult.address,
      await ethers.getSigner(from)
    );

    const authorizedSenders = await contract.getAuthorizedSenders() as string[];

    if (config.authorizedSenders.length !== authorizedSenders.length
      || config.authorizedSenders.some((value, i) => value !== authorizedSenders[i])) {
      await contract.setAuthorizedSenders(config.authorizedSenders);
    }
  };
}
