import { deployer, zkUpgrades } from 'hardhat';
import * as assert from 'assert';

const { NAME, PROXY_ADDRESS } = process.env;

async function main() {
  assert.ok(NAME && PROXY_ADDRESS);

  const [artifact, wallet] = await Promise.all([
    deployer.loadArtifact(NAME),
    deployer.getWallet(),
  ]);

  await zkUpgrades.upgradeProxy(wallet, PROXY_ADDRESS, artifact);
}

main();
