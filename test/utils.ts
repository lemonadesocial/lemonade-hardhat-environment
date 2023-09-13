import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';
import { expect } from 'chai';

export async function expectBalances(...addresses: string[]) {
  const before: BigNumber[] = [];

  for (const address of addresses) {
    before.push(await ethers.provider.getBalance(address));
  }

  return async (...expected: ((before: BigNumber) => BigNumber)[]) => {
    for (let i = 0; i < addresses.length; i++) {
      const actual = await ethers.provider.getBalance(addresses[i]);

      expect(actual).to.eq(expected[i](before[i]));
    }
  };
}
