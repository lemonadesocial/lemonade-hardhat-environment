import { BigNumber, Contract } from 'ethers';
import { ethers } from 'hardhat';
import { expect } from 'chai';

async function getBalance(address: string, pullPayment: Contract) {
  const [balance, payments] = await Promise.all([
    ethers.provider.getBalance(address),
    pullPayment.payments(address),
  ]);

  return balance.add(payments);
}

export async function expectBalances(addresses: string[], pullPayment: Contract) {
  const before: BigNumber[] = [];

  for (const address of addresses) {
    before.push(await getBalance(address, pullPayment));
  }

  return async (expected: ((before: BigNumber) => BigNumber)[]) => {
    for (let i = 0; i < addresses.length; i++) {
      const actual = await getBalance(addresses[i], pullPayment);

      expect(actual).to.eq(expected[i](before[i]));
    }
  };
}
