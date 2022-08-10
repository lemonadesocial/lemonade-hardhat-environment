import { ethers } from 'hardhat';
import type { DeployFunction, DeployOptions } from 'hardhat-deploy/types';

interface Entry {
  role: string;
  account: string;
  grant: boolean;
}

export function deployFunction(entries: Entry[], options: DeployOptions): DeployFunction {
  return async function ({ deployments: { deploy } }) {
    const deployResult = await deploy('AccessRegistry', options);

    const contract = await ethers.getContractAt(
      deployResult.abi,
      deployResult.address,
      await ethers.getSigner(options.from)
    );

    for (const entry of entries) {
      const role = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(entry.role));

      const granted = await contract.hasRole(role, entry.account);

      if (entry.grant && !granted) {
        await contract.grantRole(role, entry.account);
      } else if (!entry.grant && granted) {
        await contract.revokeRole(role, entry.account);
      }
    }
  };
}
