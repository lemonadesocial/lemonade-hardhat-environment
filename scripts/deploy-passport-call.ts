import { ethers, upgrades } from 'hardhat';

const { CALL_ADDRESS, NAME, SYMBOL, PRICE_AMOUNT, PRICE_FEED_1, PRICE_FEED_2, INCENTIVE, TREASURY, DRAWER } = process.env;

async function main() {
  const contractFactory = await ethers.getContractFactory('PassportV1Call');

  const proxy = await upgrades.deployProxy(contractFactory, [
    CALL_ADDRESS,
    NAME,
    SYMBOL,
    PRICE_AMOUNT,
    PRICE_FEED_1 || ethers.constants.AddressZero,
    PRICE_FEED_2 || ethers.constants.AddressZero,
    INCENTIVE,
    TREASURY,
    DRAWER
  ]);

  console.log(proxy.address);
}

main();
