import { ethers, upgrades } from 'hardhat';
import * as assert from 'assert';

const { NAME, PROXY_ADDRESS } = process.env;

async function main() {
  assert.ok(NAME && PROXY_ADDRESS);

  const contractFactory = await ethers.getContractFactory(NAME);

  const upgrade = await upgrades.prepareUpgrade(PROXY_ADDRESS, contractFactory);

  console.info(upgrade);
}

main();
