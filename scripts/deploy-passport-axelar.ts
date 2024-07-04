import { ethers, upgrades } from 'hardhat';

const { AXELAR_GATEWAY, AXELAR_GAS_SERVICE, AXELAR_BASE_NETWORK_CHAIN, AXELAR_BASE_NETWORK_CONTRACT_ADDRESS, NAME, SYMBOL, PRICE_AMOUNT, PRICE_FEED_1, PRICE_FEED_2, INCENTIVE, TREASURY, DRAWER } = process.env;

const AXELAR_BASE_NETWORK = ethers.keccak256(ethers.toUtf8Bytes('BASE_NETWORK'));

async function main() {
  const contractFactory = await ethers.getContractFactory('PassportV1Axelar');

  const proxy = await upgrades.deployProxy(contractFactory, [
    AXELAR_GATEWAY,
    AXELAR_GAS_SERVICE,
    [[AXELAR_BASE_NETWORK, [AXELAR_BASE_NETWORK_CHAIN, AXELAR_BASE_NETWORK_CONTRACT_ADDRESS]]],
    NAME,
    SYMBOL,
    PRICE_AMOUNT,
    PRICE_FEED_1 || ethers.ZeroAddress,
    PRICE_FEED_2 || ethers.ZeroAddress,
    INCENTIVE,
    TREASURY,
    DRAWER
  ]);

  console.log(proxy.address);
}

main();
