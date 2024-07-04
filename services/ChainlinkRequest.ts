import { BigNumberish } from 'ethers';
import { ethers } from 'hardhat';
import type { DeployFunction } from 'hardhat-deploy/types';

interface Config {
  chainlinkToken: string;
  chainlinkOracle: string;
  jobId: string;
  fee: BigNumberish;
  url: string;
}

export function deployFunction(config: Config): DeployFunction {
  const jobId = ethers.toUtf8Bytes(config.jobId);

  return async function ({ deployments: { deploy }, getNamedAccounts }) {
    const { deployer: from } = await getNamedAccounts();

    const deployResult = await deploy('ChainlinkRequest', {
      from,
      log: true,
    });

    const contract = await ethers.getContractAt(
      deployResult.abi,
      deployResult.address,
      await ethers.getSigner(from),
    );

    const current = await contract.config();

    if (!(
      current[0] === ethers.getAddress(config.chainlinkToken) &&
      current[1] === ethers.getAddress(config.chainlinkOracle) &&
      current[2] === ethers.hexlify(jobId) &&
      current[3].eq(config.fee) &&
      current[4] === config.url
    )) {
      await contract.configure(config.chainlinkToken, config.chainlinkOracle, jobId, config.fee, config.url);
    }
  };
}
