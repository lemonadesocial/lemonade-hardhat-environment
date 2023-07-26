import { ethers, upgrades } from 'hardhat';

const { AXELAR_GATEWAY, AXELAR_GAS_SERVICE, AXELAR_NETWORKS, CALL_ADDRESS, MAX_SUPPLY } = process.env;

async function main() {
  const contractFactory = await ethers.getContractFactory('BaseV1');

  const proxy = await upgrades.deployProxy(contractFactory, [
    AXELAR_GATEWAY,
    AXELAR_GAS_SERVICE,
    AXELAR_NETWORKS && JSON.parse(AXELAR_NETWORKS) || [],
    CALL_ADDRESS || ethers.constants.AddressZero,
    MAX_SUPPLY,
  ]);

  console.log(proxy.address);
}

main();
