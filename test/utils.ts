import { Contract, ContractTransactionResponse } from 'ethers';
import { ethers } from 'hardhat';
import { assert, expect } from 'chai';
import BigNumber from 'bignumber.js';

async function getBalance(address: string, pullPayment: Contract) {
  const [balance, payments] = await Promise.all([
    ethers.provider.getBalance(address),
    pullPayment.payments(address),
  ]);

  return new BigNumber(balance.toString()).plus(payments.toString());
}

export function toHex(value: BigNumber) {
  return `0x${value.toString(16)}`;
}

export async function expectBalances(addresses: string[], pullPayment: Contract) {
  const before: BigNumber[] = [];

  for (const address of addresses) {
    const balance = await getBalance(address, pullPayment);
    before.push(balance);
  }

  return async (expected: ((before: BigNumber) => BigNumber)[]) => {
    for (let i = 0; i < addresses.length; i++) {
      const actual = await getBalance(addresses[i], pullPayment);

      expect(actual.toString()).to.eq(expected[i](before[i]).toString());
    }
  };
}

export async function expectEmittedEventWithArgs(contract: Contract, tx: ContractTransactionResponse, event: string, args: Record<string, unknown>) {
  const receipt = await tx.wait();

  const log = receipt?.logs.map(log => contract.interface.parseLog(log)).find((log) => log?.name === event);

  assert.ok(log);

  for (const [key, value] of Object.entries(args)) {
    const paramIndex = log.fragment.inputs.findIndex((param) => param.name === key);

    expect(log.args[paramIndex]).to.eq(value);
  }
}

export function toId(value: string) {
  return ethers.keccak256(ethers.AbiCoder.defaultAbiCoder().encode(["string"], [value]));
}
