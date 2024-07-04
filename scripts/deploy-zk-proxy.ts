import { deployer, zkUpgrades } from 'hardhat';
import * as assert from 'assert';

const { NAME, ARGS } = process.env;

async function main() {
  assert.ok(NAME);

  const [artifact, wallet] = await Promise.all([
    deployer.loadArtifact(NAME),
    deployer.getWallet(),
  ]);

  const proxy = await zkUpgrades.deployProxy(wallet, artifact, ARGS && JSON.parse(ARGS) || []);

  console.log(proxy.target);
}

main();
