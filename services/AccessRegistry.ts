import { Contract } from "ethers";
import { ethers } from 'hardhat';
import type { DeployFunction } from 'hardhat-deploy/types';

interface Entry {
  role: string;
  account: string;
  grant: boolean;
}

async function manageRoles(contract: Contract, entries: Entry[]) {
  for (const entry of entries) {
    const role = ethers.keccak256(ethers.toUtf8Bytes(entry.role));

    const granted = await contract.hasRole(role, entry.account);

    if (entry.grant && !granted) {
      await contract.grantRole(role, entry.account);
    } else if (!entry.grant && granted) {
      await contract.revokeRole(role, entry.account);
    }
  }
}

export function deployFunction(entries: Entry[]): DeployFunction {
  return async function ({ deployments: { deploy }, getNamedAccounts }) {
    const { deployer: from } = await getNamedAccounts();

    const deployResult = await deploy('AccessRegistry', {
      from,
      log: true,
    });

    const contract = await ethers.getContractAt(
      deployResult.abi,
      deployResult.address,
      await ethers.getSigner(from),
    );

    await manageRoles(contract, entries);
  };
}

export function deployZkFunction(entries: Entry[]): DeployFunction {
  return async function ({ deployer, getNamedAccounts }) {
    const { deployer: from } = await getNamedAccounts();

    const deployResult = await deployer.deploy('AccessRegistry');

    const contract = await ethers.getContractAt(
      'AccessRegistry',
      await deployResult.getAddress(),
      await ethers.getSigner(from),
    );

    await manageRoles(contract, entries);
  }
}
