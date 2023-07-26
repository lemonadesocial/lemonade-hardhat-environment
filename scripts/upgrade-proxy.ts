import { ethers, upgrades } from 'hardhat';
import * as assert from 'assert';

const { NAME, PROXY_ADDRESS } = process.env;

async function main() {
  assert.ok(NAME && PROXY_ADDRESS);

  const contractFactory = await ethers.getContractFactory(NAME);

  await upgrades.upgradeProxy(PROXY_ADDRESS, contractFactory);
}

main();
