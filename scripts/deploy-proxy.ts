import { ethers, upgrades } from 'hardhat';
import * as assert from 'assert';

const { NAME, ARGS } = process.env;

async function main() {
  assert.ok(NAME);

  const contractFactory = await ethers.getContractFactory(NAME);

  const proxy = await upgrades.deployProxy(contractFactory, ARGS && JSON.parse(ARGS) || []);

  console.log(proxy.target);
}

main();
