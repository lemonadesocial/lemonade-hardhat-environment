import { ethers, upgrades } from 'hardhat';
import * as assert from 'assert';

const { NAME } = process.env;

async function main() {
  assert.ok(NAME);

  const contractFactory = await ethers.getContractFactory(NAME);

  const proxy = await upgrades.deployProxy(contractFactory);

  console.log(proxy.address);
}

main();
