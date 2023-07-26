import { ethers, upgrades } from 'hardhat';

const { PASSPORT } = process.env;

async function main() {
  const contractFactory = await ethers.getContractFactory('CrowdfundV1');

  const proxy = await upgrades.deployProxy(contractFactory, [
    PASSPORT,
  ]);

  console.log(proxy.address);
}

main();
